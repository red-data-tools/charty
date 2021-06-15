module Charty
  module Plotters
    class ScatterPlotter < RelationalPlotter
      def initialize(data: nil, variables: {}, **options, &block)
        x, y, color, style, size = variables.values_at(:x, :y, :color, :style, :size)
        super(x, y, color, style, size, data: data, **options, &block)
      end

      attr_reader :alpha

      def alpha=(val)
        case val
        when nil, :auto, 0..1
          @alpha = val
        when "auto"
          @alpha = val.to_sym
        when Numeric
          raise ArgumentError,
                "the given alpha is out of bounds " +
                "(%p for nil, :auto, or number 0..1)" % val
        else
          raise ArgumentError,
                "invalid value of alpha " +
                "(%p for nil, :auto, or number in 0..1)" % val
        end
      end

      attr_reader :line_width, :edge_color

      def line_width=(val)
        @line_width = check_number(val, :line_width, allow_nil: true)
      end

      def edge_color=(val)
        @line_width = check_color(val, :edge_color, allow_nil: true)
      end

      private def render_plot(backend, **)
        draw_points(backend)
        annotate_axes(backend)
      end

      private def draw_points(backend)
        map_color(palette: palette, order: color_order, norm: color_norm)
        map_size(sizes: sizes, order: size_order, norm: size_norm)
        map_style(markers: markers, order: style_order)

        data = @plot_data.drop_na

        # TODO: shold pass key_color to backend's scatter method.
        #       In pyplot backend, it is passed as color parameter.

        x = data[:x]
        y = data[:y]
        color = data[:color] if @variables.key?(:color)
        style = data[:style] if @variables.key?(:style)
        size = data[:size] if @variables.key?(:size)

        # TODO: key_color
        backend.scatter(
          x, y, @variables,
          color: color, color_mapper: @color_mapper,
          style: style, style_mapper: @style_mapper,
          size: size, size_mapper: @size_mapper
        )

        if legend
          backend.add_scatter_plot_legend(@variables, @color_mapper, @size_mapper, @style_mapper, legend)
        end
      end

      private def annotate_axes(backend)
        xlabel = self.variables[:x]
        ylabel = self.variables[:y]
        backend.set_xlabel(xlabel) unless xlabel.nil?
        backend.set_ylabel(ylabel) unless ylabel.nil?
      end
    end
  end
end
