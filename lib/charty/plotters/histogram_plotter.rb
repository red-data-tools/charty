module Charty
  module Plotters
    class HistogramPlotter < DistributionPlotter
      def univariate?
        self.variables.key?(:x) != self.variables.key?(:y)
      end

      def univariate_variable
        unless univariate?
          raise TypeError, "This is not a univariate plot"
        end
        ([:x, :y] & self.variables.keys)[0]
      end

      attr_reader :stat

      def stat=(val)
        @stat = check_stat(val)
      end

      private def check_stat(val)
        case val
        when :count, "count"
          val.to_sym
        when :frequency, "frequency",
             :density, "density",
             :probability, "probability"
          raise ArgumentError,
                "%p for `stat` is not supported yet" % val,
                caller
        else
          raise ArgumentError,
                "Invalid value for `stat` (%p)" % val,
                caller
        end
      end

      attr_reader :bins

      def bins=(val)
        @bins = check_bins(val)
      end

      private def check_bins(val)
        case val
        when :auto, "auto"
          val.to_sym
        when Integer
          val
        else
          raise ArgumentError,
                "Invalid value for `bins` (%p)" % val,
                caller
        end
      end

      # TODO: bin_width

      attr_reader :bin_range

      def bin_range=(val)
        @bin_range = check_bin_range(val)
      end

      private def check_bin_range(val)
        case val
        when nil, Range
          return val
        when Array
          if val.length == 2
            val.each_with_index do |v, i|
              check_number(v, "bin_range[#{i}]")
            end
            return val
          else
            amount = val.length < 2 ? "few" : "many"
            raise ArgumentError,
                  "Too #{amount} items in `bin_range` array (%p for 2)" % val.length
          end
        else
          raise ArgumentError,
                "Invalid value for `bin_range` " +
                "(%p for a range or a pair of numbers)" % val
        end
      end

      # TODO: discrete
      # TODO: cumulative

      attr_reader :common_bins

      def common_bins=(val)
        @common_bins = check_boolean(val, :common_bins)
      end

      # TODO: common_norm

      attr_reader :multiple

      def multiple=(val)
        @multiple = check_multiple(val)
      end

      private def check_multiple(val)
        case val
        when :layer, "layer"
          val.to_sym
        when :dodge, "dodge",
             :stack, "stack",
             :fill, "fill"
          val = val.to_sym
          raise NotImplementedError,
                "%p for `multiple` is not supported yet" % val,
                caller
        else
          raise ArgumentError,
                "Invalid value for `multiple` (%p)" % val,
                caller
        end
      end

      # TODO: element
      # TODO: fill
      # TODO: shrink

      attr_reader :kde

      def kde=(val)
        raise NotImplementedError, "kde is not supported yet"
      end

      attr_reader :kde_params

      def kde_params=(val)
        raise NotImplementedError, "kde_params is not supported yet"
      end

      # TODO: thresh
      # TODO: pthresh
      # TODO: pmax
      # TODO: cbar
      # TODO: cbar_params
      # TODO: x_log_scale
      # TODO: y_log_scale

      private def render_plot(backend, **)
        draw_univariate_histogram(backend)
        annotate_axes(backend)
      end

      private def draw_univariate_histogram(backend)
        map_color(palette: palette, order: color_order, norm: color_norm)

        key_color = self.key_color
        if key_color.nil? && !self.variables.key?(:color)
          palette = case self.palette
                    when Palette
                      self.palette
                    when nil
                      Palette.default
                    else
                      Palette[self.palette]
                    end
          key_color = palette[0]
        end

        # TODO: calculate histogram here and use bar plot to visualize
        data_variable = self.univariate_variable

        if common_bins
          all_data = processed_data.drop_na
          all_observations = all_data[data_variable].to_a

          bins = self.bins
          bins = 10 if self.variables.key?(:color) && bins == :auto

          case bins
          when Integer
            case bin_range
            when Range
              start = bin_range.begin
              stop  = bin_range.end
            when Array
              start, stop = bin_range.minmax
            end
            data_range = all_observations.minmax
            start ||= data_range[0]
            stop ||= data_range[1]
            if start == stop
              start -= 0.5
              stop += 0.5
            end
            common_bin_edges = Linspace.new(start .. stop, bins + 1).map(&:to_f)
          else
            params = {}
            params[:weights] = all_data[:weights].to_a if all_data.column?(:weights)
            h = Statistics.histogram(all_observations, bins, **params)
            common_bin_edges = h.edges
          end
        end

        if self.variables.key?(:color)
          alpha = 0.5
        else
          alpha = 0.75
        end

        each_subset([:color], processed: true) do |sub_vars, sub_data|
          observations = sub_data[data_variable].drop_na.to_a
          params = {}
          params[:weights] = sub_data[:weights].to_a if sub_data.column?(:weights)
          params[:edges] = common_bin_edges if common_bin_edges
          hist = Statistics.histogram(observations, bins, **params)

          name = sub_vars[:color]
          backend.univariate_histogram(hist, name, data_variable, stat,
                                       alpha, name, key_color, @color_mapper,
                                       multiple, :bars, true, 1r)
        end
      end

      private def annotate_axes(backend)
        if univariate?
          xlabel = self.variables[:x]
          ylabel = self.variables[:y]
          case self.univariate_variable
          when :x
            ylabel = self.stat.to_s.capitalize
          else
            xlabel = self.stat.to_s.capitalize
          end
          backend.set_ylabel(ylabel) if ylabel
          backend.set_xlabel(xlabel) if xlabel

          if self.variables.key?(:color)
            backend.legend(loc: :best, title: self.variables[:color])
          end
        end
      end
    end
  end
end
