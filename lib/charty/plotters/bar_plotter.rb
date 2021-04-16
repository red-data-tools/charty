module Charty
  module Plotters
    class BarPlotter < CategoricalPlotter
      def initialize(data: nil, variables: {}, order: nil, orient: nil, **options, &block)
        x, y, color = variables.values_at(:x, :y, :color)
        super(x, y, color, data: data, order: order, orient: orient, **options, &block)
      end

      attr_reader :error_color

      def error_color=(error_color)
        # TODO: check value
        @error_color = error_color
      end

      attr_reader :error_width

      def error_width=(error_width)
        # TODO: check value
        @error_width = error_width
      end

      attr_reader :cap_size

      def cap_size=(cap_size)
        # TODO: check value
        @cap_size = cap_size
      end

      attr_reader :dodge

      def dodge=(dodge)
        # TODO: check value
        @dodge = dodge
      end

      def render
        backend = Backends.current
        backend.begin_figure
        draw_bars(backend)
        annotate_axes(backend)
        backend.show
      end

      private def draw_bars(backend)
        statistic = @plot_data.map {|xs| Statistics.mean(xs) }
        bar_pos = (0 ... statistic.length).to_a
        backend.bar(bar_pos, statistic, color: @colors)
      end
    end
  end
end
