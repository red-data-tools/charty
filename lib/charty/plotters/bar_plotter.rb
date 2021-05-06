module Charty
  module Plotters
    class BarPlotter < CategoricalPlotter
      self.default_palette = :light
      self.require_numeric = true

      def initialize(data: nil, variables: {}, **options, &block)
        x, y, color = variables.values_at(:x, :y, :color)
        super(x, y, color, data: data, **options, &block)
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
        @error_width = check_number(error_width, :error_width, allow_nil: true)
      end

      attr_reader :cap_size

      def cap_size=(cap_size)
        @cap_size = check_number(cap_size, :cap_size, allow_nil: true)
      end

      def render
        backend = Backends.current
        backend.begin_figure
        draw_bars(backend)
        annotate_axes(backend)
        backend.invert_yaxis if orient == :h
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
        backend.invert_yaxis if orient == :h
        backend.save(filename, **opts)
      end

      private def draw_bars(backend)
        setup_estimations


        if @plot_colors.nil?
          bar_pos = (0 ... @estimations.length).to_a
          error_colors = bar_pos.map { error_color }
          backend.bar(bar_pos, @estimations, @colors, orient,
                      conf_int: @conf_int, error_colors: error_colors,
                      error_width: error_width, cap_size: cap_size)
        else
          bar_pos = (0 ... @estimations[0].length).to_a
          error_colors = bar_pos.map { error_color }
          offsets = color_offsets
          width = nested_width
          @color_names.each_with_index do |color_name, i|
            pos = bar_pos.map {|x| x + offsets[i] }
            colors = Array.new(@estimations[i].length) { @colors[i] }
            backend.bar(pos, @estimations[i], colors, orient,
                        label: color_name, width: width,
                        conf_int: @conf_int[i], error_colors: error_colors,
                        error_width: error_width, cap_size: cap_size)
          end
        end
      end

      private def setup_estimations
        if @color_names.nil?
          setup_estimations_with_single_color_group
        else
          setup_estimations_with_multiple_color_groups
        end
      end

      private def setup_estimations_with_single_color_group
        estimations = []
        conf_int = []

        @plot_data.each do |group_data|
          # Single color group
          if @plot_units.nil?
            stat_data = group_data.drop_na
            unit_data = nil
          else
            # TODO: Support units
          end

          estimation = if stat_data.size == 0
                         Float::NAN
                       else
                         # TODO: Support other estimations
                         stat_data.mean
                       end
          estimations << estimation

          unless ci.nil?
            if stat_data.size < 2
              conf_int << [Float::NAN, Float::NAN]
              next
            end

            if ci == :sd
              sd = stat_data.stdev
              conf_int << [estimation - sd, estimation + sd]
            else
              conf_int << Statistics.bootstrap_ci(stat_data, ci, func: estimator, n_boot: n_boot,
                                                  units: unit_data, random: random)
            end
          end
        end

        @estimations = estimations
        @conf_int = conf_int
      end

      private def setup_estimations_with_multiple_color_groups
        estimations = Array.new(@color_names.length) { [] }
        conf_int = Array.new(@color_names.length) { [] }

        @plot_data.each_with_index do |group_data, i|
          @color_names.each_with_index do |color_name, j|
            if @plot_colors[i].length == 0
              estimations[j] << Float::NAN
              unless ci.nil?
                conf_int[j] << [Float::NAN, Float::NAN]
              end
              next
            end

            color_mask = @plot_colors[i].eq(color_name)
            if @plot_units.nil?
              begin
              stat_data = group_data[color_mask].drop_na
              rescue
                @plot_data.each_with_index {|pd, k| p k => pd }
                @plot_colors.each_with_index {|pc, k| p k => pc }
                raise
              end
              unit_data = nil
            else
              # TODO: Support units
            end

            estimation = if stat_data.size == 0
                           Float::NAN
                         else
                           # TODO: Support other estimations
                           stat_data.mean
                         end
            estimations[j] << estimation

            unless ci.nil?
              if stat_data.size < 2
                conf_int[j] << [Float::NAN, Float::NAN]
                next
              end

              if ci == :sd
                sd = stat_data.stdev
                conf_int[j] << [estimation - sd, estimation + sd]
              else
                conf_int[j] << Statistics.bootstrap_ci(stat_data, ci, func: estimator, n_boot: n_boot,
                                                       units: unit_data, random: random)
              end
            end
          end
        end

        @estimations = estimations
        @conf_int = conf_int
      end
    end
  end
end
