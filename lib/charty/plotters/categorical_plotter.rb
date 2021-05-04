module Charty
  module Plotters
    class CategoricalPlotter < AbstractPlotter
      class << self
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

      def initialize(x, y, color, **options, &block)
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

        x = Charty::Vector.try_convert(x)
        y = Charty::Vector.try_convert(y)

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

          # FIXME: Assume groups has only unique values
          @group_names = categorical_order(groups, order)
          @plot_data, @value_label = group_long_form(vals, groups, @group_names)
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

      # TODO: move to AbstractPlotter
      private def categorical_order(vector, order=nil)
        if order.nil?
          case
          when vector.categorical?
            order = vector.categories
          else
            order = vector.unique_values
            order.sort! if vector.numeric?
          end
          order.compact!
        end
        order
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
        n_colors = @plot_data.length
        if @palette.nil?
          current_palette = Palette.default
          if n_colors <= current_palette.n_colors
            palette = Palette.new(current_palette.colors, n_colors)
          else
            palette = Palette.new(:husl, n_colors, desaturate_factor: 0.7r)
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
