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

      attr_reader :log

      def log=(val)
        @log = check_boolean(val, :log)
      end

      private def render_plot(backend, **)
        draw_bars(backend)
        annotate_axes(backend)
        backend.invert_yaxis if orient == :h
      end

      private def draw_bars(backend)
        setup_estimations

        if @plot_colors.nil?
          bar_pos = (0 ... @estimations.length).to_a
          error_colors = bar_pos.map { error_color }
          if @conf_int.empty?
            ci_params = {}
          else
            ci_params = {conf_int: @conf_int, error_colors: error_colors,
                         error_width: error_width, cap_size: cap_size}
          end
          backend.bar(bar_pos, nil, @estimations, @colors, orient, **ci_params)
        else
          bar_pos = (0 ... @estimations[0].length).to_a
          error_colors = bar_pos.map { error_color }
          offsets = color_offsets
          width = nested_width
          @color_names.each_with_index do |color_name, i|
            pos = bar_pos.map {|x| x + offsets[i] }
            colors = Array.new(@estimations[i].length) { @colors[i] }
            if @conf_int[i].empty?
              ci_params = {}
            else
              ci_params = {conf_int: @conf_int[i], error_colors: error_colors,
                           error_width: error_width, cap_size: cap_size}
            end
            backend.bar(pos, @group_names, @estimations[i], colors, orient,
                        label: color_name, width: width, **ci_params)
          end
        end
      end

      private def annotate_axes(backend)
        super

        if self.log
          if @plot_colors
            min_value = @estimations.map(&:min).min
            max_value = @estimations.map(&:max).max
            unless @conf_int.empty?
              ci_min = @conf_int.map {|cis| cis.map {|ci| ci[0] }.min }.min
              ci_max = @conf_int.map {|cis| cis.map {|ci| ci[1] }.max }.max
              min_value = [min_value, ci_min].min
              max_value = [max_value, ci_max].max
            end
          else
            min_value, max_value = @estimations.minmax
            ci_min = Util.filter_map(@conf_int) { |ci| ci[0] unless ci.empty? }
            ci_max = Util.filter_map(@conf_int) { |ci| ci[1] unless ci.empty? }
            min_value = [min_value, *ci_min].min
            max_value = [max_value, *ci_max].max
          end
          if min_value > 1
            min_value = 0
          else
            min_value = Math.log10(min_value).floor
          end
          max_value = Math.log10(max_value).ceil
          case self.orient
          when :v
            backend.set_yscale(:log)
            backend.set_ylim(min_value, max_value)
          else
            backend.set_xscale(:log)
            backend.set_xlim(min_value, max_value)
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
                         estimate(estimator, stat_data)
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
                           estimate(estimator, stat_data)
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

      private def estimate(estimator, data)
        case estimator
        when :count
          data.length
        when :mean
          data.mean
        else
          # TODO: Support other estimations
          raise NotImplementedError, "#{estimator} estimator is not supported yet"
        end
      end
    end
  end
end
