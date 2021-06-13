module Charty
  module Plotters
    class BaseMapper
      def initialize(plotter, *params)
        @plotter = plotter
        initialize_mapping(*params)
      end

      attr_reader :plotter

      def [](key, *args)
        case key
        when Array, Charty::Vector
          key.map {|k| lookup_single_value(k, *args) }
        else
          lookup_single_value(key, *args)
        end
      end

      private def categorical_lut_from_hash(levels, pairs, name)
        missing_keys = levels - pairs.keys
        unless missing_keys.empty?
          raise ArgumentError,
                "The `#{name}` hash is missing keys: %p" % missing_keys
        end
        pairs.dup
      end

      private def categorical_lut_from_array(levels, values, name)
        if levels.length != values.length
          raise ArgumentError,
            "The `#{name}` array has the wrong number of values " +
            "(%d for %d)." % [values.length, levels.length]
        end
        levels.zip(values).to_h
      end
    end

    # TODO: This should be replaced with red-colors's Normalize feature
    class SimpleNormalizer
      def initialize(vmin=nil, vmax=nil)
        @vmin = vmin
        @vmax = vmax
      end

      attr_accessor :vmin, :vmax

      def call(value, clip=nil)
        scalar_p = false
        vector_p = false
        case value
        when Charty::Vector
          vector_p = true
          value = value.to_a
        when Array
          # do nothing
        else
          scalar_p = true
          value = [value]
        end

        @vmin = value.min if vmin.nil?
        @vmax = value.max if vmax.nil?

        result = value.map {|x| (x - vmin) / (vmax - vmin).to_f }

        case
        when scalar_p
          result[0]
        when vector_p
          Charty::Vector.new(result, index: value.index)
        else
          result
        end
      end
    end

    class ColorMapper < BaseMapper
      private def initialize_mapping(palette, order, norm)
        if plotter.variables.key?(:color)
          data = plotter.plot_data[:color]
        end

        if data && data.notnull.any?
          @map_type = infer_map_type(@palette, @norm, @plotter.input_format, @plotter.var_types[:color])

          case @map_type
          when :numeric
            @levels, @lookup_table, @norm, @cmap = numeric_mapping(data, @palette, norm)
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

      private def numeric_mapping(data, palette, norm)
        case palette
        when Hash
          levels = palette.keys.sort
          colors = palette.values_at(*levels)
          cmap = Colors::ListedColormap.new(colors)
          lookup_table = palette.dup
        else
          levels = data.drop_na.unique_values
          levels.sort!

          palette ||= "ch:"
          cmap = case palette
                 when Colors::Colormap
                   palette
                 else
                   Palette.new(palette, 256).to_colormap
                 end

          case norm
          when nil
            norm = SimpleNormalizer.new
          when Array
            norm = SimpleNormalizer.new(*norm)
          #when Colors::Normalizer
          # TODO: Must support red-color's Normalize feature
          else
            raise ArgumentError,
                  "`color_norm` must be nil, Array, or Normalizer object"
          end

          # initialize norm
          norm.(data.drop_na.to_a)

          lookup_table = levels.map { |level|
            [
              level,
              cmap[norm.(level)]
            ]
          }.to_h
        end

        return levels, lookup_table, norm, cmap
      end

      private def categorical_mapping(data, palette, order)
        levels = data.categorical_order(order)
        n_colors = levels.length

        case palette
        when Hash
          lookup_table = categorical_lut_from_hash(levels, palette, :palette)
          return levels, lookup_table

        when nil
          current_palette = Palette.default
          if n_colors <= current_palette.n_colors
            colors = Palette.new(current_palette.colors, n_colors).colors
          else
            colors = Palette.husl_colors(n_colors)
          end

        when Array
          colors = palette

        else
          colors = Palette.new(palette, n_colors).colors
        end

        lookup_table = categorical_lut_from_array(levels, colors, :palette)
        return levels, lookup_table
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

      attr_reader :palette, :norm, :levels, :lookup_table, :map_type

      def inverse_lookup_table
        lookup_table.invert
      end

      def lookup_single_value(key)
        if @lookup_table.key?(key)
          @lookup_table[key]
        elsif @norm
          # Use the colormap to interpolate between existing datapoints
          begin
            normed = @norm.(key)
            @cmap[normed]
          rescue ArgumentError, TypeError => err
            if Util.nan?(key)
              return "#000000"
            else
              raise err
            end
          end
        end
      end
    end

    class SizeMapper < BaseMapper
      private def initialize_mapping(sizes, order, norm)
        @sizes = sizes
        @order = order
        @norm = norm

        return unless plotter.variables.key?(:size)

        data = plotter.plot_data[:size]
        return unless data.notnull.any?

        @map_type = infer_map_type(sizes, norm, @plotter.var_types[:size])
        case @map_type
        when :numeric
          @levels, @lookup_table, @norm = numeric_mapping(data, sizes, norm)
        when :categorical
          @levels, @lookup_table = categorical_mapping(data, sizes, order)
        else
          raise NotImplementedError,
                "datetime color mapping is not supported"
        end
      end

      private def infer_map_type(sizes, norm, var_type)
        case
        when ! norm.nil?
          :numeric
        when sizes.is_a?(Hash),
             sizes.is_a?(Array)
          :categorical
        else
          var_type
        end
      end

      private def numeric_mapping(data, sizes, norm)
        case sizes
        when Hash
          # The presence of a norm object overrides a dictionary of sizes
          # in specifying a numeric mapping, so we need to process the
          # dictionary here
          levels = sizes.keys.sort
          size_values = sizes.values
          size_range = [size_values.min, size_values.max]
        else
          levels = Charty::Vector.new(data.unique_values).drop_na.to_a
          levels.sort!

          case sizes
          when Range
            size_range = [sizes.begin, sizes.end]
          when nil
            size_range = [0r, 1r]
          else
            raise ArgumentError,
                  "Unable to recognize the value for `sizes`: %p" % sizes
          end
        end

        # Now we have the minimum and the maximum values of sizes
        case norm
        when nil
          norm = SimpleNormalizer.new
          sizes_scaled = norm.(levels)
        # when Colors::Normalize
        # TODO: Must support red-color's Normalize feature
        else
          raise ArgumentError,
                "Unable to recognize the value for `norm`: %p" % norm
        end

        case sizes
        when Hash
          # do nothing
        else
          lo, hi = size_range
          sizes = sizes_scaled.map {|x| lo + x * (hi - lo) }
          lookup_table = levels.zip(sizes).to_h
        end

        return levels, lookup_table, norm
      end

      private def categorical_mapping(data, sizes, order)
        levels = data.categorical_order(order)

        case sizes
        when Hash
          lookup_table = categorical_lut_from_hash(levels, sizes, :sizes)
          return levels, lookup_table

        when Array
          # nothing to do

        when Range, nil
          # Reverse values to use the largest size for the first category
          size_range = sizes || (0r .. 1r)
          sizes = Linspace.new(size_range, levels.length).reverse_each.to_a
        else
          raise ArgumentError,
            "Unable to recognize the value for `sizes`: %p" % sizes
        end

        lookup_table = categorical_lut_from_array(levels, sizes, :sizes)
        return levels, lookup_table
      end

      attr_reader :palette, :order, :norm, :levels, :lookup_table, :map_type

      def lookup_single_value(key)
        if @lookup_table.key?(key)
          @lookup_table[key]
        else
          normed = @norm.(key) || Float::NAN
          size_values = @lookup_table.values
          min, max = size_values.min, size_values.max
          min + normed * (max - min)
        end
      end
    end

    class StyleMapper < BaseMapper
      private def initialize_mapping(markers, dashes, order)
        @markers = markers
        @dashes = dashes
        @order = order

        return unless plotter.variables.key?(:style)

        data = plotter.plot_data[:style]
        return unless data.notnull.any?

        @levels = data.categorical_order(order)

        markers = map_attributes(markers, @levels, unique_markers(@levels.length), :markers)
        dashes = map_attributes(dashes, @levels, unique_dashes(@levels.length), :dashes)

        @lookup_table = @levels.map {|key|
          record = {
            marker: markers[key],
            dashes: dashes[key]
          }
          [key, record]
        }.to_h
      end

      MARKER_NAMES = [
        :circle,      :x,           :square,        :cross,   :diamond, :star_diamond,
        :triangle_up, :star_square, :triangle_down, :hexagon, :star,    :pentagon,
      ].freeze

      private def unique_markers(n)
        if n > MARKER_NAMES.length
          raise ArgumentError,
                "Too many markers are required (%p for %p)" % [n, MARKER_NAMES.length]
        end
        MARKER_NAMES[0, n]
      end

      DASH_NAMES = [
        :solid, :dash, :dot, :dashdot, :longdashdot, :longdash,
      ].freeze

      private def unique_dashes(n)
        if n > DASH_NAMES.length
          raise ArgumentError,
                "Too many dash patterns are required " +
                "(%p for %p)" % [n, DASH_NAMES.length]
        end
        DASH_NAMES[0, n]
      end

      private def map_attributes(vals, levels, defaults, attr)
        case vals
        when true
          return levels.zip(defaults).to_h
        when Hash
          missing_keys = lavels - vals.keys
          unless missing_keys.empty?
            raise ArgumentError,
                  "The `%s` levels are missing values: %p" % [attr, missing_keys]
          end
          return vals
        when Array, Enumerable
          if levels.length != vals.length
            raise ArgumentError,
                  "%he `%s` argument has the wrong number of values" % attr
          end
          return levels.zip(vals).to_h
        when nil
          return {}
        else
          raise ArgumentError,
                "Unable to recognize the value for `%s`: %p" % [attr, vals]
        end
      end

      attr_reader :palette, :order, :norm, :lookup_table, :levels

      def inverse_lookup_table(attr)
        lookup_table.map { |k, v| [v[attr], k] }.to_h
      end

      def lookup_single_value(key, attr=nil)
        case attr
        when nil
          @lookup_table[key]
        else
          @lookup_table[key][attr]
        end
      end
    end

    class RelationalPlotter < AbstractPlotter
      def initialize(x, y, color, style, size, data: nil, **options, &block)
        super(x, y, color, data: data, **options, &block)

        self.style = style
        self.size = size

        setup_variables
      end

      attr_reader :style, :size

      attr_reader :color_norm

      attr_reader :sizes, :size_order, :size_norm

      attr_reader :markers, :dashes, :style_order

      attr_reader :legend

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
        # NOTE: the value check will be perfomed in SizeMapper
        @sizes = val
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
        @markers = check_markers(val)
      end

      private def check_markers(val)
        # TODO
        val
      end

      def dashes=(val)
        @dashes = check_dashes(val)
      end

      private def check_dashes(val)
        # TODO
        val
      end

      def style_order=(val)
        unless val.nil?
          raise NotImplementedError,
                "Specifying style_order is not supported yet"
        end
      end

      def legend=(val)
        case val
        when :auto, :brief, :full, false
          @legend = val
        when "auto", "brief", "full"
          @legend = val.to_sym
        else
          raise ArgumentError,
                "invalid value of legend (%p for :auto, :brief, :full, or false)" % val
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
        self.data = {} if data.nil?

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

          if data.column?(val)
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
