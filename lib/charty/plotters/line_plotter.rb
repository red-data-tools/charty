module Charty
  module Plotters
    class EstimateAggregator
      def initialize(estimator, error_bar, n_boot, random)
        @estimator = estimator
        @method, @level = error_bar
        @n_boot = n_boot
        @random = random
      end

      # Perform aggregation
      #
      # @param data [Hash<Any, Charty::Table>]
      # @param var_name [Symbol, String]  A column name to be aggregated
      def aggregate(data, var_name)
        values = data[var_name]
        estimation = case @estimator
                     when :count
                       values.length
                     when :mean
                       values.mean
                     end

        n = values.length
        case
        # No error bars
        when @method.nil?
          err_min = err_max = Float::NAN
        when n <= 1
          err_min = err_max = Float::NAN

        # User-defined method
        when @method.respond_to?(:call)
          err_min, err_max = @method.call(values)

        # Parametric
        when @method == :sd
          err_radius = values.stdev * @level
          err_min = estimation - err_radius
          err_max = estimation + err_radius
        when @method == :se
          err_radius = values.stdev / Math.sqrt(n)
          err_min = estimation - err_radius
          err_max = estimation + err_radius

        # Nonparametric
        when @method == :pi
          err_min, err_max = percentile_interval(values, @level)
        when @method == :ci
          # TODO: Support units
          err_min, err_max =
            Statistics.bootstrap_ci(values, @level, units: nil, func: @estimator,
                                    n_boot: @n_boot, random: @random)
        end

        {
          var_name => estimation,
          "#{var_name}_min" => err_min,
          "#{var_name}_max" => err_max
        }
      end

      def percentile_interval(values, width)
        q = [50 - width / 2, 50 + width / 2]
        Statistics.percentile(values, q)
      end
    end

    class LinePlotter < RelationalPlotter
      def initialize(data: nil, variables: {}, **options, &block)
        x, y, color, style, size = variables.values_at(:x, :y, :color, :style, :size)
        super(x, y, color, style, size, data: data, **options, &block)

        @comp_data = nil
      end

      include EstimationSupport

      undef_method :ci, :ci=, :check_ci

      attr_reader :sort, :err_style, :err_kws, :error_bar, :x_scale, :y_scale

      def sort=(val)
        @sort = check_boolean(val, :sort)
      end

      def err_style=(val)
        @err_style = check_err_style(val)
      end

      private def check_err_style(val)
        case val
        when :bars, "bars", :band, "band"
          val.to_sym
        else
          raise ArgumentError,
                "Invalid value for err_style (%p for :band or :bars)" % val
        end
      end

      # parameters to draw error bars/bands
      def err_params=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying `err_params` is not supported"
        end
      end

      # The method and level to calculate error bars/bands
      def error_bar=(val)
        @error_bar = check_error_bar(val)
      end

      DEFAULT_ERROR_BAR_LEVELS = {
        ci: 95,
        pi: 95,
        se: 1,
        sd: 1
      }.freeze

      VALID_ERROR_BAR_METHODS = DEFAULT_ERROR_BAR_LEVELS.keys
      VALID_ERROR_BAR_METHODS.concat(VALID_ERROR_BAR_METHODS.map(&:to_s))
      VALID_ERROR_BAR_METHODS.freeze

      private def check_error_bar(val)
        case val
        when nil
          return [nil, nil]
        when ->(x) { x.respond_to?(:call) }
          return [val, nil]
        when *VALID_ERROR_BAR_METHODS
          method = val.to_sym
          level = nil
        when Array
          if val.length != 2
            raise ArgumentError,
                  "The `error_bar` array has the wrong number of items " +
                  "(%d for 2)" % val.length
          end
          method, level = *val
        else
          raise ArgumentError,
                "Unable to recognize the value for `error_bar`: %p" % val
        end

        case method
        when *VALID_ERROR_BAR_METHODS
          method = method.to_sym
        else
          error_message = "The value for method in `error_bar` array must be in %p, but %p was passed" % [
            DEFAULT_ERROR_BAR_LEVELS.keys,
            method
          ]
          raise ArgumentError, error_message
        end

        case level
        when Numeric
          # nothing to do
        else
          raise ArgumentError,
                "The value of level in `error_bar` array must be a number "
        end

        [method, level]
      end

      def x_scale=(val)
        @x_scale = check_axis_scale(val, :x)
      end

      def y_scale=(val)
        @y_scale = check_axis_scale(val, :y)
      end

      private def check_axis_scale(val, axis)
        case val
        when :linear, "linear", :log10, "log10"
          val.to_sym
        else
          raise ArgumentError,
                "The value of `#{axis}_scale` is worng: %p" % val,
                caller
        end
      end

      private def render_plot(backend, **)
        draw_lines(backend)
        annotate_axes(backend)
      end

      private def draw_lines(backend)
        map_color(palette: palette, order: color_order, norm: color_norm)
        map_size(sizes: sizes, order: size_order, norm: size_norm)
        map_style(markers: markers, dashes: dashes, order: style_order)

        aggregator = EstimateAggregator.new(estimator, error_bar, n_boot, random)

        agg_var = :y
        grouper = :x
        grouping_vars = [:color, :size, :style]

        each_subset(grouping_vars, processed: true) do |sub_vars, sub_data|
          if self.sort
            sort_cols = [:units, :x, :y] & self.variables.keys
            sub_data = sub_data.sort_values(sort_cols)
          end

          unless estimator.nil?
            if self.variables.include?(:units)
              raise "`estimator` is must be nil when specifying `units`"
            end

            grouped = sub_data.group_by(grouper, sort: self.sort)
            sub_data = grouped.apply(agg_var, &aggregator.method(:aggregate)).reset_index
          end

          # TODO: perform inverse conversion of axis scaling before plot

          unit_grouping = if self.variables.include?(:units)
                            sub_data.group_by(:units)
                          else
                            { nil => sub_data }
                          end
          unit_grouping.each do |_unit_value, unit_data|
            ci_params = unless self.estimator.nil? || self.error_bar.nil?
                          {
                            style: self.err_style,
                            y_min: sub_data[:y_min],
                            y_max: sub_data[:y_max]
                          }
                        end
            backend.line(unit_data[:x], unit_data[:y],
                         color: sub_vars[:color], color_mapper: @color_mapper,
                         size: sub_vars[:size], size_mapper: @size_mapper,
                         style: sub_vars[:style], style_mapper: @style_mapper,
                         ci_params: ci_params)
          end
        end
      end

      private def annotate_axes(backend)
        xlabel = self.variables[:x]
        ylabel = self.variables[:y]
        backend.set_xlabel(xlabel) unless xlabel.nil?
        backend.set_ylabel(ylabel) unless ylabel.nil?

        if legend
          #add_legend_data(backend)
        end
      end
    end
  end
end
