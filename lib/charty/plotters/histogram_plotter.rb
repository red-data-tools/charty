module Charty
  module Plotters
    class HistogramPlotter < DistributionPlotter
      def univariate?
        self.variables.key?(:x) != self.variables.key?(:y)
      end

      def univariate_variable
        unless univariate?
          raise TypeError, "This is not a univariate plot"
        end
        ([:x, :y] & self.variables.keys)[0]
      end

      attr_reader :weights

      def weights=(val)
        @weights = check_weights(val)
      end

      private def check_weights(val)
        raise NotImplementedError, "weights is not supported yet"
      end

      attr_reader :stat

      def stat=(val)
        @stat = check_stat(val)
      end

      private def check_stat(val)
        case val
        when :count, "count"
          val.to_sym
        when :frequency, "frequency",
             :density, "density",
             :probability, "probability"
          raise ArgumentError,
                "%p for `stat` is not supported yet" % val,
                caller
        else
          raise ArgumentError,
                "Invalid value for `stat` (%p)" % val,
                caller
        end
      end

      attr_reader :bins

      def bins=(val)
        @bins = check_bins(val)
      end

      private def check_bins(val)
        case val
        when :auto, "auto"
          val.to_sym
        when Integer
          val
        else
          raise ArgumentError,
                "Invalid value for `bins` (%p)" % val,
                caller
        end
      end

      # TODO: bin_width
      # TODO: bin_range
      # TODO: discrete
      # TODO: cumulative
      # TODO: common_bins
      # TODO: common_norm

      attr_reader :multiple

      def multiple=(val)
        @multiple = check_multiple(val)
      end

      private def check_multiple(val)
        case val
        when :layer, "layer"
          val.to_sym
        when :dodge, "dodge",
             :stack, "stack",
             :fill, "fill"
          val = val.to_sym
          raise NotImplementedError,
                "%p for `multiple` is not supported yet" % val,
                caller
        else
          raise ArgumentError,
                "Invalid value for `multiple` (%p)" % val,
                caller
        end
      end

      # TODO: element
      # TODO: fill
      # TODO: shrink

      attr_reader :kde

      def kde=(val)
        raise NotImplementedError, "kde is not supported yet"
      end

      attr_reader :kde_params

      def kde_params=(val)
        raise NotImplementedError, "kde_params is not supported yet"
      end

      # TODO: thresh
      # TODO: pthresh
      # TODO: pmax
      # TODO: cbar
      # TODO: cbar_params
      # TODO: x_log_scale
      # TODO: y_log_scale

      private def render_plot(backend, **)
        draw_univariate_histogram(backend)
        annotate_axes(backend)
      end

      private def draw_univariate_histogram(backend)
        map_color(palette: palette, order: color_order, norm: color_norm)

        # TODO: calculate histogram here and use bar plot to visualize
        data_variable = self.univariate_variable

        histograms = {}
        each_subset([:color], processed: true) do |sub_vars, sub_data|
          key = sub_vars.to_a
          observations = sub_data[data_variable].drop_na.to_a
          hist = Statistics.histogram(observations)
          histograms[key] = hist
        end

        bin_start, bin_end, bin_size = nil
        histograms.each do |_, hist|
          s, e = hist.edge.minmax
          z = (e - s).to_f / (hist.edge.length - 1)
          bin_start = [bin_start, s].compact.min
          bin_end   = [bin_end, e].compact.max
          bin_size  = [bin_size, z].compact.min
        end

        if self.variables.key?(:color)
          alpha = 0.5
        else
          alpha = 0.75
        end

        each_subset([:color], processed: true) do |sub_vars, sub_data|
          name = sub_vars[:color]
          observations = sub_data[data_variable].drop_na.to_a

          backend.univariate_histogram(observations, name, data_variable, stat,
                                       bin_start, bin_end, bin_size, alpha,
                                       name, @color_mapper)
        end
      end

      private def annotate_axes(backend)
        if univariate?
          xlabel = self.variables[:x]
          ylabel = self.variables[:y]
          case self.univariate_variable
          when :x
            ylabel = self.stat.to_s.capitalize
          else
            xlabel = self.stat.to_s.capitalize
          end
          backend.set_ylabel(ylabel) if ylabel
          backend.set_xlabel(xlabel) if xlabel
        end
      end
    end
  end
end
