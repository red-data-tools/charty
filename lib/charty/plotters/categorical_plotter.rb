module Charty
  module Plotters
    class CategoricalPlotter < AbstractPlotter
      class << self
        attr_reader :default_palette

        def default_palette=(val)
          case val
          when :light, :dark
            @default_palette = val
          when "light", "dark"
            @default_palette = val.to_sym
          else
            raise ArgumentError, "default_palette must be :light or :dark"
          end
        end

        attr_reader :require_numeric

        def require_numeric=(val)
          case val
          when true, false
            @require_numeric = val
          else
            raise ArgumentError, "require_numeric must be ture or false"
          end
        end
      end

      def initialize(x, y, color, order: nil, orient: nil, width: 0.8r, dodge: false, **options, &block)
        super

        setup_variables
        setup_colors
      end

      attr_reader :order

      def order=(order)
        @order = order && Array(order).map(&method(:normalize_name))
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

      attr_reader :width

      def width=(val)
        @width = check_number(val, :width)
      end

      attr_reader :dodge

      def dodge=(dodge)
        @dodge = check_boolean(dodge, :dodge)
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

      attr_reader :group_names, :plot_data, :group_label

      attr_accessor :value_label

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
        x = self.x
        y = self.y
        color = self.color
        if @data
          x &&= @data[x] || x
          y &&= @data[y] || y
          color &&= @data[color] || color
        end

        # Validate inputs
        [x, y, color].each do |input|
          next if input.nil? || array?(input)
          raise RuntimeError,
                "Could not interpret input `#{input.inspect}`"
        end

        x = Charty::Vector.try_convert(x)
        y = Charty::Vector.try_convert(y)
        color = Charty::Vector.try_convert(color)

        self.orient = infer_orient(x, y, orient, self.class.require_numeric)

        if x.nil? || y.nil?
          setup_single_data
        else
          if orient == :v
            groups, vals = x, y
          else
            groups, vals = y, x
          end

          if groups.respond_to?(:name)
            @group_label = groups.name
          end

          @group_names = groups.categorical_order(order)
          @plot_data, @value_label = group_long_form(vals, groups, @group_names)

          # Handle color variable
          if color.nil?
            @plot_colors = nil
            @color_title = nil
            @color_names = nil
          else
            # Get the order of color levels
            @color_names = color.categorical_order(color_order)

            # Group the color data
            @plot_colors, @color_title = group_long_form(color, groups, @group_names)
          end

          # TODO: Handle units
        end
      end

      private def setup_single_data
        raise NotImplementedError,
              "Single data plot is not supported yet"
      end

      private def infer_orient(x, y, orient, require_numeric)
        x_type = x.nil? ? nil : variable_type(x)
        y_type = y.nil? ? nil : variable_type(y)

        nonnumeric_error = "%{orient} orientation requires numeric `%{dim}` variable"
        single_variable_warning = "%{orient} orientation ignored with only `%{dim}` specified"

        case
        when x.nil?
          case orient
          when :h
            warn single_variable_warning % {orient: "Horizontal", dim: "y"}
          end
          if require_numeric && y_type != :numeric
            raise ArgumentError, nonnumeric_error % {orient: "Vertical", dim: "y"}
          end
          return :v
        when y.nil?
          case orient
          when :v
            warn single_variable_warning % {orient: "Vertical", dim: "x"}
          end
          if require_numeric && x_type != :numeric
            raise ArgumentError, nonnumeric_error % {orient: "Horizontal", dim: "x"}
          end
          return :h
        end
        case orient
        when :v
          if require_numeric && y_type != :numeric
            raise ArgumentError, nonnumeric_error % {orient: "Vertical", dim: "y"}
          end
          return :v
        when :h
          if require_numeric && x_type != :numeric
            raise ArgumentError, nonnumeric_error % {orient: "Horizontal", dim: "x"}
          end
          return :h
        when nil
          case
          when x_type != :categorical && y_type == :categorical
            return :h
          when x_type != :numeric     && y_type == :numeric
            return :v
          when x_type == :numeric     && y_type != :numeric
            return :h
          when require_numeric && x_type != :numeric && y_type != :numeric
            raise ArgumentError, "Neither the `x` nor `y` variable appears to be numeric."
          else
            :v
          end
        else
          # must be unreachable
          raise RuntimeError, "BUG in Charty. Please report the issue."
        end
      end

      private def variable_type(vector, boolean_type=:numeric)
        if vector.numeric?
          :numeric
        elsif vector.categorical?
          :categorical
        else
          case vector[0]
          when true, false
            boolean_type
          else
            :categorical
          end
        end
      end

      private def group_long_form(vals, groups, group_order)
        grouped_vals = vals.group_by(groups)

        plot_data = group_order.map {|g| grouped_vals[g] || [] }

        if vals.respond_to?(:name)
          value_label = vals.name
        end

        return plot_data, value_label
      end

      private def setup_colors
        if @color_names.nil?
          n_colors = @plot_data.length
        else
          n_colors = @color_names.length
        end

        if key_color.nil? && self.palette.nil?
          # Check the current palette has enough colors
          current_palette = Palette.default
          if n_colors <= current_palette.n_colors
            colors = Palette.new(current_palette.colors, n_colors).colors
          else
            # Use huls palette as default when the default palette is not usable
            colors = Palette.husl_colors(n_colors, l: 0.7r)
          end
        elsif self.palette.nil?
          if @color_names.nil?
            colors = Array.new(n_colors) { key_color }
          else
            raise NotImplementedError,
                  "Default palette with key_color is not supported"
            # TODO: Support light_palette and dark_palette in red-palette
            # if default_palette is light
            #   colors = Palette.light_palette(key_color, n_colors)
            # elsif default_palette is dark
            #   colors = Palette.dark_palette(key_color, n_colors)
            # else
            #   raise "No default palette specified"
            # end
          end
        else
          case self.palette
          when Hash
            if @color_names.nil?
              levels = @group_names
            else
              levels = @color_names
            end
            colors = levels.map {|gn| self.palette[gn] }
          end
          colors = Palette.new(colors, n_colors).colors
        end

        if saturation < 1
          colors = Palette.new(colors, n_colors, desaturate_factor: saturation).colors
        end

        @colors = colors.map {|c| c.to_rgb }
        lightness_values = @colors.map {|c| c.to_hsl.l }
        lum = lightness_values.min * 0.6r
        @gray = Colors::RGB.new(lum, lum, lum)  # TODO: Use Charty::Gray
      end

      private def color_offsets
        n_names = @color_names.length
        if self.dodge
          each_width = @width / n_names
          offsets = Charty::Linspace.new(0 .. (@width - each_width), n_names).to_a
          offsets_mean = Statistics.mean(offsets)
          offsets.map {|x| x - offsets_mean }
        else
          Array.new(n_names) { 0 }
        end
      end

      private def nested_width
        if self.dodge
          @width / @color_names.length * 0.98r
        else
          @width
        end
      end

      private def annotate_axes(backend)
        if orient == :v
          xlabel, ylabel = @group_label, @value_label
        else
          xlabel, ylabel = @value_label, @group_label
        end
        backend.set_xlabel(xlabel) unless xlabel.nil?
        backend.set_ylabel(ylabel) unless ylabel.nil?

        if orient == :v
          backend.set_xticks((0 ... @plot_data.length).to_a)
          backend.set_xtick_labels(@group_names)
        else
          backend.set_yticks((0 ... @plot_data.length).to_a)
          backend.set_ytick_labels(@group_names)
        end

        if orient == :v
          backend.disable_xaxis_grid
          backend.set_xlim(-0.5, @plot_data.length - 0.5)
        else
          backend.disable_yaxis_grid
          backend.set_ylim(-0.5, @plot_data.length - 0.5)
        end

        unless @color_names.nil?
          backend.legend(loc: :best, title: @color_title)
        end
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
