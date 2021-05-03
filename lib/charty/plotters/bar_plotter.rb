module Charty
  module Plotters
    class BarPlotter < CategoricalPlotter
      def initialize(data: nil, variables: {}, order: nil, orient: nil, **options, &block)
        x, y, color = variables.values_at(:x, :y, :color)
        super(x, y, color, data: data, order: order, orient: orient, **options, &block)
      end

      attr_reader :error_color

      def error_color=(error_color)
        @error_color = check_error_color(error_color)
      end

      private def check_error_color(value)
        case value
        when Colors::AbstractColor
          value
        when Array
          Colors::RGB.new(*value)
        when String
          # TODO: Use Colors.parse when it'll be available
          Colors::RGB.parse(value)
        else
          raise ArgumentError,
                "invalid value for error_color (%p for a color, a RGB tripret, or a RGB hex string)" % value
        end
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

      # TODO:
      # - Should infer mime type from file's extname
      # - Should check backend's supported mime type before begin_figure
      def save(filename, **opts)
        backend = Backends.current
        backend.begin_figure
        draw_bars(backend)
        annotate_axes(backend)
        backend.save(filename, **opts)
      end

      private def draw_bars(backend)
        setup_estimations

        bar_pos = (0 ... @statistic.length).to_a
        error_colors = bar_pos.map { error_color }
        backend.bar(bar_pos, @statistic, @colors, orient,
                    conf_int: @conf_int, error_colors: error_colors, error_width: error_width, cap_size: cap_size)
      end

      private def setup_estimations
        statistic = []
        conf_int = []

        @plot_data.each do |group_data|
          stat_data = group_data.drop_na

          estimation = if stat_data.size == 0
                         Float::NAN
                       else
                         stat_data.mean
                       end
          statistic << estimation

          if ci
            if stat_data.size < 2
              conf_int << [Float::NAN, Float::NAN]
              next
            end

            if ci == :sd
              sd = stat_data.stdev
              conf_int << [estimation - sd, estimation + sd]
            else
              conf_int << Statistics.bootstrap_ci(stat_data, ci, func: estimator, n_boot: n_boot, units: nil, random: random)
            end
          end
        end

        @statistic = statistic
        @conf_int = conf_int
      end
    end
  end
end
