require "enumerable/statistics"

module Charty
  module PlotElements
    class AbstractPlot
      def initialize(x, y, color, data)
        @x = x
        @y = y
        @color = color
        @data = data
      end

      attr_reader :x, :y, :color, :data

      def x=(x)
        @x = check_dimension(new_x, :x)
      end

      def y=(y)
        @y = check_dimension(new_y, :y)
      end

      def color=(color)
        @color = check_dimension(new_color, :color)
      end

      def data=(data)
        @data = case new_data
                when Charty::Table
                  data
                else
                  Charty::Table.new(data)
                end
      end

      private def check_dimension(value, name)
        case value
        when String, Symbol
          value
        when -> { value.respond_to?(:to_str) }
          value.to_str
        when method(:arrayable?)
          value
        else
          raise ArgumentError, "invalid type of dimension for #{name}", caller
        end
      end

      private def name?(value)
        case value
        when String, Symbol
             -> { value.respond_to?(:to_str) }
          true
        else
          false
        end
      end

      private def array?(value)
        TableAdapters::HashAdapter.array?(value)
      end
    end

    class CategoricalPlot < AbstractPlot
      def initialize(*args)
        super

        @width = 0.8r
        @default_palette = :light
      end

      # A list of center positions for plots when color nesting is used.
      def color_offsets(i)
        n_levels = @color_names.length
        if @dodge
          each_with = @width / n_levels
          offsets = Numo::DFloat.linspace(0, @width - each_width, n_levels)
          offsets.inplace - offsets.mean
        else
          offsets = Numo::DFloat.zeros(n_levels)
        end
        Array(offsets)
      end

      # Add descriptive labels to axes
      def annotate_axes(ctx)
        # axis labels
        if @orient == :v
          xlabel, ylabel = @group_label, @value_label
        else
          xlabel, ylabel = @value_label, @group_label
        end
        ctx.set_xlabel(xlabel) if xlabel
        ctx.set_ylabel(ylabel) if ylabel

        # ticks
        if @orient == :v
          ctx.set_xticks((0...@plot_data.length).to_a)
          ctx.set_xtick_labels(@group_names)
        else
          ctx.set_yticks((0...@plot_data.length).to_a)
          ctx.set_ytick_labels(@group_names)
        end

        # grid and limit
        if @orient == :v
          ctx.disable_xaxis_grid
          ctx.set_xlim(-0.5, @plot_data.length - 0.5)
        else
          ctx.disable_yaxis_grid
          ctx.set_ylim(-0.5, @plot_data.length - 0.5)
        end

        # legend
        if @color_names
          ctx.show_legend(location: :best)
          # TODO: seaborn adjust legend title size by axes.labelsize
          ctx.set_legend_title(@color_title) if @color_title
        end
      end

      def setup_variables(orient=nil, order=nil, color_order=nil, units=nil)
        if @x.nil? && @y.nil?
          setup_wide_form_variables(orient, order, color_order, units)
        else
          setup_long_form_variables(orient, order, color_order, units)
        end
      end

      def setup_wide_form_variables(orient, order, color_order, units)
        raise NotImplementedError,
              "Wide form support is not implemented"
      end

      def setup_long_form_variables(orient, order, color_order, units)
        if @data
          x = (name?(@x) && data[@x]) || @x
          y = (name?(@y) && data[@y]) || @y
          color = (name?(@color) && data[@color]) || @color
          units = (name?(units) && data[units]) || units
        end

        # Input validation
        [x, y, color, units].each do |input|
          if name?(input)
            raise ArgumentError, "Could not interpret input `#{input}`"
          end
        end

        orient = infer_orient(x, y, orient)

        if x.nil? || y.nil?
          # Plotting a single set of data
          vals = x.nil? ? y : x

          plot_data = [Array(vals)]
          if vals.respond_to?(:name)
            value_label = vals.name
          else
            value_label = nil
          end

          # This plot won't have group labels or color nesting
          groups = nil
          group_label = nil
          group_names = []
          plot_colors = nil
          color_names = nil
          color_title = nil
          plot_units = nil
        else
          # Grouping the data values by another variable

          # Determine which role each variable will play
          if orient == :v
            vals, groups = y, x
          else
            vals, groups = x, y
          end

          if groups.respond_to?(:name)
            group_name = groups.name
          else
            group_name = nil
          end

          group_names = categorical_order(groups, order) # TODO

          plot_data, value_label = group_long_form(vals, groups, group_names) # TODO

          if color.nil?
            plot_colors = nil
            color_title = nil
            color_names = nil
          else
            color_names = categorical_order(color, color_order)
            plot_colors, color_title = group_long_form(color, groups, group_name)
          end

          if units.nil?
            plot_units = nil
          else
            plot_units, _ = group_long_form(units, groups, group_name)
          end

          @orient = orient
          @plot_data = plot_data
          @group_label = group_label
          @value_label = value_label
          @group_names = group_names
          @plot_colors = plot_colors
          @color_title = color_title
          @color_names = color_names
          @plot_units = plot_units
        end

        # Get an array of colors for the main component of the plots.
        def setup_colors(seed_color, palette, saturation)
          n_colors = (@color_names || @plot_data).length

          # Determine the main colors
          if seed_color.nil? && palette.nil?
            # Determine whether the current palette will have enough values.
            # If not, we'll default to the HUSL palette so each is distinct
            current_palette = Charty::Palette.default
            if n_colors <= current_palette.n_colors
              colors = Charty::Palette.new(current_palette, n_colors)
            else
              colors = Charty::Palette.husl(n_colors, l: 0.7r)
            end
          elsif palette.nil?
            # When passing a specific color, the interpretation depends on
            # whether there is a color variable or not.
            # If so, we will make a blend palette so that the different
            # levels have some amount of variation
            if @color_names.nil?
              colors = Array.new(n_colors) { seed_color }
            else
              if @default_palette == :light
                colors = Charty::Palette.light(seed_color, n_colors)
              elsif @default_palette == :dark
                colors = Charty::Palette.dark(seed_color, n_colors)
              else
                raise "No default palette specified"
              end
            end
          else
            # Let `palette` be a dict mapping level to color
            case palette
            when Hash
              levels = @color_names || @group_names
              palette = levels.map {|l| palette[l] }
            end
            colors = Charty::Palette.new(palette, n_colors)
          end

          if saturation < 1
            colors = Charty::Palette.new(colors, desaturate_factor: saturation)
          end

          @colors = colors.map {|c| c.to_rgb }
          light_vals = @colors.map {|c| c.to_hsl.l }
          lum = light_vals.min * 0.6r
          @gray = Charty::RGB(lum, lum, lum)  # TODO: use Charty::Color::Gray

          self
        end

        # Determine how the plot should be oriented based on the data
        def infer_orient(x, y, orient=nil)
          case orient
          when Symbol, String
            # do nothing
          else
            orient = orient.to_str
          end

          is_categorical = -> (data) do
            # TODO
            false
          end

          is_not_numeric = -> (data) do
            # TODO
            false
          end

          no_numeric_message = "Neither the `x` nor `y` variable appears to be numeric."

          if orient.start_with?("v")
            :v
          elsif orient.start_with?("h")
            :h
          elsif x.nil?
            :v
          elsif y.nil?
            :h
          elsif is_categorical.(y)
            if is_categorical.(x)
              raise ArgumentError, no_numeric_message
            else
              :h
            end
          elsif is_not_numeric.(y)
            if is_not_numeric.(x)
              raise ArgumentError, no_numeric_message
            else
              :h
            end
          else
            :v
          end
        end

        # Returns a list of unique data values
        #
        # @param values [#categories, #uniq, Array, Numo::NArray, Pandas::Series]
        #   Vector of categorical values
        # @param order [Array, Numo::NArray, #to_ary]
        #   Desired order of category levels to override the order
        #   determined from the `values` object.
        #
        # @return [Array]
        #   Ordered array of category levels not including null values.
        private def categorical_order(values, order=nil)
          if order.nil?
            if value.respond_to?(:categories)
              order = values.categories
            elsif value.respond_to?(:uniq)
              order = values.uniq
            elsif defined?(Pandas::Series) && values.is_a?(Pandas::Series)
              order = values.cat.categories
            else
              order = Array(values).uniq
            end
            Array(order).sort
          end
          Array(order).compact
        end

        # Group a long-form variable by another with correct order.
        private def group_long_form(vals, grouper, order)
          if defined?(Pandas::Series) && vals.is_a?(Pandas::Series)
            # The special case for pandas.Series
            grouped_vals = vals.groupby(grouper)
            out_data = []
            order.each do |g|
              begin
                g_vals = Array(grouped_vals.get_group(g))
              rescue PyCall::PyError
                g_vals = []
              end
              out_data << g_vals
            end

            label = vals.name
          elsif vals.respond_to?(:group_by)
            grouped_vals = vals.group_by.with_index {|_, i| grouper[i] }
            out_data = order.map {|g| grouped_vals[g] || [] }
            label = vals&.name
          end

          [out_data, label]
        end
      end
    end

    class CategoricalStatsPlot < CategoricalPlot
      # A float with the width of plot elements when color nesting is used.
      def nested_width
        if @dodge
          @width / @color_names.length * 0.98r
        else
          @width
        end
      end

      # Calculate statistical summary values and confidential intervals
      def estimate_statistic(estimator=:mean)
        unless estimator.respond_to?(:call)
          case estimator
          when Symbol
            estimator = method(:"estimate_#{estimator}")
          else
            raise ArgumentError, "invalid estimator: #{estimator.inspect}"
          end
        end

        if @color_names.nil
          statistic = []
          confidential_interval = []
        else
          statistic = Array.new(@plot_data.length) { [] }
          confidential_interval = Array.new(@plot_data.length) { [] }
        end

        @plot_data.each_with_index do |group_data, i|
          if @plot_colors.nil?
            # (1) We have a single layer of grouping
            if @plot_units.nil?
              stat_data = remove_na(@group_data)
              unit_data = nil
            else
              # TODO
              raise NotImplementedError,
                    "plot_units isn't supported yet"
            end

            # Estimate a statistic from the vector of data
            estimation = if stat_data.empty?
                           Float::NAN
                         else
                           estimator.(stat_data)
                         end
            statistic << estimation

            # Get a confidence interval for this estimation
            if @ci
              if stat_data.length < 2
                confidential_interval << [Float::NAN, Float::NAN]
                next
              end

              if ci == :sd
                sd = calculate_stdev(stat_data)
                confidential_interval << [estimation - sd, estimation + sd]
              else
                # TODO:
                # boots = bootstrap(stat_data, func: estimator, n_boot: n_boot, units: unit_data)
                # confidential_interval << calculate_ci(boots, ci)
                raise NotImplementedError,
                      "confidential interval by bootstrap isn't supported yet"
              end
            end
          else
            # (2) We are grouping by a color layer
            @color_names.each_with_index do |color_name, j|
              if @plot_colors[i].empty?
                statistic[i] << Float::NAN
                confidential_interval[i] << [Float::NAN, Float::NAN] if @ci
                next
              end

              color_mask = @plot_colors[i].map {|c| c == color_name }
              if @plot_units.nil?
                stat_data = remove_na(group_data[color_mask])
                unit_data = nil
              else
                raise NotImplementedError,
                      "plot_units isn't supported yet"
              end
            end
          end
        end
      end

      private def estimate_mean(data)
        if data.respond_to?(:mean)
          data.mean
        elsif defined?(PyCall) && data.is_a?(PyCall::PyObjectWrapper)
          begin
            numpy = PyCall.import_module("numpy")
            numpy.mean(data)
          rescue PyCall::PyError
            raise LoadError,
                  "Unable to import numpy for estimating the mean of the python object"
          end
        else
          Array(data).mean
        end
      end
    end

    class BarPlot < CategoricalStatsPlot
      def initialize(x, y, color, data, order, color_order,
                     estimator, ci, n_boot, units, orient,
                     seed_color, palette, saturation,
                     err_color, err_width, cap_size, dodge)
        super(x, y, color, data)

        yield self if block_given?

        setup_variables(orient, order, color_order, units) # TODO
        setup_colors(seed_color, palette, saturation) # TODO
        estimate_statistic(estimator, ci, n_boot) # TODO

        @dodge = dodge

        @err_color = err_color
        @err_width = err_width
        @cap_size = cap_size
      end

      def render(backend=nil)
        unless backend
          backend_class = Charty::Backends.find_backend_class(backend_name)
          backend = backend_class.new
        end

        draw_bars(backend)
        annotate_axes(backend)
      end

      def to_iruby
        render
      end

      private def draw_bars(ctx)
        bar_pos = (1...@statistics.length).to_a

        if @plot_colors.nil?
          # draw the bars
          ctx.bar(bar_pos, @statistics, width: @width, color: @colors,
                  align: :center, orient: @orient)

          # draw the confidence intervals
          err_colors = Array.new(bar_pos.length) { @err_color }
          ctx.draw_confidence_interval(bar_pos, @confidence_internval,
                                       err_colors, @err_width, @cap_size)
        else
          @color_names.each_with_index do |color_name, i|
            # draw the bars
            off_pos = bar_pos.map {|bp| bp + color_offsets(i) }
            ctx.bar(off_pos, @statistics[j], width: nested_width,
                    color: @colors[j], align: :center, label: color_name,
                    orient: @orient)

            # draw the confidence intervals
            if @confidence_interval.length > 0
              err_colors = Array.new(off_pos.length) { @err_color }
              ctx.draw_confidence_interval(off_pos, @confidence_interval[j],
                                           err_colors, @err_width, @cap_size)
            end
          end
        end
      end
    end
  end

  module PlotMethods
    # Show the given data as rectangular bars.
    #
    # @param x [String, Symbol, #to_ary, #to_a, nil]
    #   The name of variables in `data`, or a vector data.
    #   This is an optional parameter.
    # @param y [String, Symbol, #to_ary, #to_a, nil]
    #   The name of variables in `data`, or a vector data.
    #   This is an optional parameter.
    # @param color [String, Symbol, #to_ary, #to_a, nil]
    #   The name of variables in `data`, or a vector data.
    #   This is an optional parameter.
    # @param data [Charty::Table compatible object, nil]
    #   Dataset for plotting.
    #   If `x` and `y` are omitted, this is interpreted as wide-form.
    #   Otherwise it is expected to be long-form.
    def bar_plot(x=nil, y=nil, color=nil,
                 data: nil, order: nil, color_order: nil, estimator: :mean,
                 ci: 95, n_boot: 1000, units: nil, orient: nil,
                 seed_color: nil, palette: nil, saturation: 0.75,
                 err_color: 0.26r, err_width: nil, cap_size: nil, dodge: true,
                 &block)
      Charty::PlotElements::BarPlot.new(x, y, color, data, order, color_order,
                                        estimator, ci, n_boot, units, orient,
                                        seed_color, palette, saturation,
                                        err_color, err_width, cap_size, dodge,
                                        &block)
    end
  end

  extend PlotMethods
end
