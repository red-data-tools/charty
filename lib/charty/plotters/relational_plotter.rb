module Charty
  module Plotters
    class BaseMapper
      def initialize(plotter, *params)
        @plotter = plotter
        initialize_mapping(*params)
      end

      attr_reader :plotter

      def [](key)
        case key
        when Array, Charty::Vector
          key.map {|k| lookup_single_value(k) }
        else
          lookup_single_value(key)
        end
      end
    end

    class ColorMapper < BaseMapper
      private def initialize_mapping(palette, order, norm)
        @palette = palette
        @order = order
        @norm = norm

        if plotter.variables.key?(:color)
          data = plotter.plot_data[:color]
        end

        if data && data.notnull.any?
          @map_type = infer_map_type(@palette, @norm, @plotter.input_format, @plotter.var_types[:color])

          case @map_type
          when :numeric
            raise NotImplementedError,
                  "numeric color mapping is not supported"
          when :categorical
            @cmap = nil
            @norm = nil
            @levels, @lookup_table = categorical_mapping(data, @palette, @order)
          else
            raise NotImplementedError,
                  "datetime color mapping is not supported"
          end
        end
      end

      private def categorical_mapping(data, palette, order)
        levels = data.categorical_order(order)
        n_colors = levels.length

        case palette
        when Hash
          missing_keys = levels - palette.keys
          unless missing_keys.empty?
            raise ArgumentError,
                  "The palette hash is missing keys: %p" % missing_keys
          end
          return levels, palette

        when nil
          current_palette = Palette.default
          if n_colors <= current_palette.n_colors
            colors = Palette.new(current_palette.colors, n_colors).colors
          else
            colors = Palette.husl_colors(n_colors)
          end
        when Array
          if palette.length != n_colors
            raise ArgumentError,
                  "The palette list has the wrong number of colors"
          end
          colors = palette
        else
          colors = Palette.new(palette, n_colors).colors
        end
        lookup_table = levels.zip(colors).to_h

        return levels, lookup_table
      end

      attr_reader :palette, :order, :norm

      def lookup_single_value(key)
        if @lookup_table.key?(key)
          @lookup_table[key]
        elsif @norm
          # Use the colormap to interpolate between existing datapoints
          raise NotImplementedError,
                "Palette interpolation is not implemented yet"
          # begin
          #   normed = @norm.(key)
          # rescue ArgumentError, TypeError => err
          #   if key.respond_to?(:nan?) && key.nan?
          #     return "#000000"
          #   else
          #     raise err
          #   end
          # end
        end
      end

      private def infer_map_type(palette, norm, input_format, var_type)
        case
        when false # palette is qualitative_palette
          :categorical
        when ! norm.nil?
          :numeric
        when palette.is_a?(Array),
             palette.is_a?(Hash)
          :categorical
        when input_format == :wide
          :categorical
        else
          var_type
        end
      end


      # TODO
    end

    class SizeMapper < BaseMapper
      private def initialize_mapping(sizes, order, norm)
        @sizes = sizes
        @order = order
        @norm = norm

        # TODO
      end

      attr_reader :palette, :order, :norm

      def lookup_single_value(key)
        # TODO
      end

      # TODO
    end

    class StyleMapper < BaseMapper
      private def initialize_mapping(markers, dashes, order)
        @markers = markers
        @dashes = dashes
        @order = order
      end

      attr_reader :palette, :order, :norm

      def lookup_single_value(key)
        # TODO
      end

      # TODO
    end

    class RelationalPlotter < AbstractPlotter
      def initialize(x, y, color, stype, size, data: nil, **options, &block)
        super(x, y, color, data: data, **options, &block)

        self.style = style
        self.size = size

        setup_variables
      end

      attr_reader :style, :size

      attr_reader :color_norm

      attr_reader :sizes, :size_order, :size_norm

      attr_reader :markers, :marker_order

      def style=(val)
        @style = check_dimension(val, :style)
      end

      def size=(val)
        @size = check_dimension(val, :size)
      end

      def color_norm=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying color_norm is not supported yet"
        end
      end

      def sizes=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying sizes is not supported yet"
        end
      end

      def size_order=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying size_order is not supported yet"
        end
      end

      def size_norm=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying size_order is not supported yet"
        end
      end

      def markers=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying markers is not supported yet"
        end
      end

      def marker_order=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying marker_order is not supported yet"
        end
      end

      attr_reader :input_format, :plot_data, :variables, :var_types

      private def setup_variables
        if x.nil? && y.nl?
          @input_format = :wide
          setup_variables_with_wide_form_dataset
        else
          @input_format = :long
          setup_variables_with_long_form_dataset
        end

        @var_types = @plot_data.columns.map { |k|
          [k, variable_type(@plot_data[k], :categorical)]
        }.to_h
      end

      private def setup_variables_with_wide_form_dataset
        unless color.nil? && style.nil? && size.nil?
          vars = []
          vars << "color" unless color.nil?
          vars << "style" unless style.nil?
          vars << "size"  unless size.nil?
          raise ArgumentError,
                "Unable to assign the following variables in wide-form data: " +
                vars.join(", ")
        end

        if data.nil? || data.empty?
          @plot_data = Charty::Table.new({})
          @variables = {}
          return
        end

        # TODO: detect flat data
        flat = false

        if flat
          # TODO: Support flat data
        else
          raise NotImplementedError,
                "wide-form input is not supported"
        end
      end

      private def setup_variables_with_long_form_dataset
        if data.nil? || data.empty?
          @plot_data = Charty::Table.new({})
          @variables = {}
          return
        end

        plot_data = {}
        variables = {}

        {
          x: self.x,
          y: self.y,
          color: self.color,
          style: self.style,
          size: self.size
        }.each do |key, val|
          next if val.nil?

          if data.column_names.include?(val)
            plot_data[key] = data[val]
            variables[key] = val
          else
            case val
            when Charty::Vector
              plot_data[key] = val
              variables[key] = val.name
            else
              raise ArgumentError,
                    "Could not interpret value %p for parameter %p" % [val, key]
            end
          end
        end

        @plot_data = Charty::Table.new(plot_data)
        @variables = variables.select do |var, name|
          @plot_data[var].notnull.any?
        end
      end

      private def annotate_axes(backend)
        # TODO
      end

      private def map_color(palette: nil, order: nil, norm: nil)
        @color_mapper = ColorMapper.new(self, palette, order, norm)
      end

      private def map_size(sizes: nil, order: nil, norm: nil)
        @size_mapper = SizeMapper.new(self, sizes, order, norm)
      end

      private def map_style(markers: nil, dashes: nil, order: nil)
        @style_mapper = StyleMapper.new(self, markers, dashes, order)
      end
    end
  end
end
