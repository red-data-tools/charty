require "enumerable/statistics"

module Charty
  module Plotters
    class BarPlotter < AbstractPlotter
      def initialize(x, y, color, **options, &block)
        super

        setup_variables
        setup_colors
      end

      attr_reader :group_names, :plot_data, :group_label, :value_label

      private def setup_variables
        if x.nil? && y.nil?
          setup_variables_with_wide_form_dataset
        else
          setup_variables_with_long_form_dataset
        end
      end

      private def setup_variables_with_wide_form_dataset
        raise NotImplementedError,
              "wide-form dataset is not supported yet"
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
                "Could not interpret interpret input `#{input.inspect}`"
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
        @gray = Colors::RGB.new(lum, lum, lum)  # TODO: Add and use Colors::Gray
      end

      def render
        backend = Backends.current
        draw_bars(backend)
        annotate_axes(backend)
        backend.show
      end

      private def draw_bars(backend)
        statistic = @plot_data.map(&:mean)
        bar_pos = (0 ... statistic.length).to_a
        backend.bar(bar_pos, statistic, color: @colors)
      end

      private def annotate_axes(backend)
        backend.set_xlabel(@group_label)
        backend.set_ylabel(@value_label)
        backend.set_xticks((0 ... @plot_data.length).to_a)
        backend.set_xtick_labels(@group_names)
        backend.disable_xaxis_grid
        backend.set_xlim(-0.5, @plot_data.length - 0.5)
      end
    end
  end
end
