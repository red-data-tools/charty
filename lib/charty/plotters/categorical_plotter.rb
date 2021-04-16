module Charty
  module Plotters
    class CategoricalPlotter < AbstractPlotter
      def initialize(x, y, color, **options, &block)
        super

        setup_variables
        setup_colors
      end

      attr_reader :order

      def order=(order)
        @order = Array(order).map(&method(:normalize_name))
      end

      attr_reader :orient

      def orient=(orient)
        @orient = check_orient(orient)
      end

      private def check_orient(value)
        case value
        when nil, :v, :h
          value
        when "v", "h"
          value.to_sym
        else
          raise ArgumentError,
                "invalid value for orient (#{value.inspect} for nil, :v, or :h)"
        end
      end

      attr_reader :saturation

      def saturation=(saturation)
        @saturation = check_saturation(saturation)
      end

      private def check_saturation(value)
        case value
        when 0..1
          value
        when Numeric
          raise ArgumentError,
                "saturation is out of range (%p for 0..1)" % value
        else
          raise ArgumentError,
                "invalid value for saturation (%p for a value in 0..1)" % value
        end
      end

      include EstimationSupport

      private def normalize_name(value)
        case value
        when String, Symbol
          value
        else
          value.to_str
        end
      end

      attr_reader :group_names, :plot_data, :group_label, :value_label

      private def setup_variables
        if x.nil? && y.nil?
          @input_format = :wide
          setup_variables_with_wide_form_dataset
        else
          @input_format = :long
          setup_variables_with_long_form_dataset
        end
      end

      private def setup_variables_with_wide_form_dataset
        if @color
          raise ArgumentError,
                "Cannot use `color` without `x` or `y`"
        end

        # No color grouping with wide inputs
        @plot_colors = nil
        @color_title = nil
        @color_names = nil

        # No statistical units with wide inputs
        @plot_units = nil

        @value_label = nil
        @group_label = nil

        order = @order # TODO: supply order via parameter
        unless order
          order = @data.column_names.select do |cn|
            @data[cn].all? {|x| Float(x, exception: false) }
          end
        end
        order ||= @data.column_names
        @plot_data = order.map {|cn| @data[cn] }
        @group_names = order
      end

      private def setup_variables_with_long_form_dataset
        x, y = @x, @y
        if @data
          x = @data[x] || x
          y = @data[y] || y
        end

        # Validate inputs
        [x, y].each do |input|
          next if array?(input)
          raise RuntimeError,
                "Could not interpret input `#{input.inspect}`"
        end

        if x.nil? || y.nil?
          setup_single_data
        else
          # FIXME: Assume vertical plot
          groups, vals = x, y

          if groups.respond_to?(:name)
            @group_label = groups.name
          end

          if vals.respond_to?(:name)
            @value_label = vals.name
          end

          # FIXME: Assume groups has only unique values
          @group_names = groups
          @plot_data = vals.map {|v| [v] }
        end
      end

      private def setup_single_data
        raise NotImplementedError,
              "Single data plot is not supported yet"
      end

      private def setup_colors
        n_colors = @plot_data.length
        if @palette.nil?
          current_palette = Palette.default
          if n_colors <= current_palette.n_colors
            palette = Palette.new(current_palette.colors, n_colors)
          else
            palette = Palette.husl(n_colors, l: 0.7r)
          end
        else
          case @palette
          when Hash
            # Assume @palette has a hash table that maps
            # group_names to colors
            palette = @group_names.map {|gn| @palette[gn] }
          else
            palette = @palette
          end
          palette = Palette.new(palette, n_colors)
        end

        @colors = palette.colors.map {|c| c.to_rgb }
        lightness_values = @colors.map {|c| c.to_hsl.l }
        lum = lightness_values.min * 0.6r
        @gray = Colors::RGB.new(lum, lum, lum)  # TODO: Use Charty::Gray
      end

      private def annotate_axes(backend)
        backend.set_xlabel(@group_label)
        backend.set_ylabel(@value_label)
        backend.set_xticks((0 ... @plot_data.length).to_a)
        backend.set_xtick_labels(@group_names)
        backend.disable_xaxis_grid
        backend.set_xlim(-0.5, @plot_data.length - 0.5)
      end

      private def remove_na!(ary)
        ary.reject! do |x|
          next true if x.nil?
          x.respond_to?(:nan?) && x.nan?
        end
        ary
      end
    end
  end
end
