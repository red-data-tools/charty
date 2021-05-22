module Charty
  module Plotters
    class ScatterPlotter < RelationalPlotter
      def initialize(data: nil, variables: {}, **options, &block)
        x, y, color, style, size = variables.values_at(:x, :y, :color, :style, :size)
        super(x, y, color, style, size, data: data, **options, &block)
      end

      attr_reader :alpha, :legend

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

      attr_reader :line_width, :edge_color

      def line_width=(val)
        @line_width = check_number(val, :line_width, allow_nil: true)
      end

      def edge_color=(val)
        @line_width = check_color(val, :edge_color, allow_nil: true)
      end

      def render
        backend = Backends.current
        backend.begin_figure
        draw_points(backend)
        annotate_axes(backend)
        backend.show
      end

      def save(filename, **opts)
        backend = Backends.current
        backend.begin_figure
        draw_points(backend)
        annotate_axes(backend)
        backend.save(filename, **opts)
      end

      private def draw_points(backend)
        map_color(palette: palette, order: color_order, norm: color_norm)
        map_size(sizes: sizes, order: size_order, norm: size_norm)
        map_style(markers: markers, order: marker_order)

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
          size: size, size_mapper: @size_mapper,
          legend: legend
        )
      end

      private def annotate_axes(backend)
        xlabel = self.variables[:x]
        ylabel = self.variables[:y]
        backend.set_xlabel(xlabel) unless xlabel.nil?
        backend.set_ylabel(ylabel) unless ylabel.nil?

        if legend
          add_legend_data(backend)
        end
      end

      private def add_legend_data(backend)
        # TODO: Legend Support
        verbosity = legend
        verbosity = :auto if verbosity == true

        titles = Util.filter_map([:color, :size, :style]) do |v|
          variables[v] if variables.key?(v)
        end
        legend_title = titles.length == 1 ? titles[0] : ""
      end
    end
  end
end
