require 'pycall'

module Charty
  module Backends
    class Bokeh < Base
      Name = "bokeh"

      def initialize
        @plot = PyCall.import_module('bokeh.plotting')
      end

      def series=(series)
        @series = series
      end

      def render(context, filename)
        plot = plot(context)
        save(plot, context, filename)
        PyCall.import_module('bokeh.io').show(plot)
      end

      def save(plot, context, filename)
        if filename
          PyCall.import_module('bokeh.io').save(plot, filename)
        end
      end

      def plot(context)
        #TODO To implement boxplot, bublle, error_bar, hist.

        plot = @plot.figure(title: context&.title)
        plot.xaxis[0].axis_label = context&.xlabel
        plot.yaxis[0].axis_label = context&.ylabel

        case context.method
          when :bar
            context.series.each do |data|
              diffs = data.xs.to_a.each_cons(2).map {|n, m| (n - m).abs }
              width = diffs.min * 0.8
              plot.vbar(data.xs.to_a, width, data.ys.to_a)
            end

          when :barh
            context.series.each do |data|
              diffs = data.xs.to_a.each_cons(2).map {|n, m| (n - m).abs }
              height = diffs.min * 0.8
              plot.hbar(data.xs.to_a, height, data.ys.to_a)
            end

          when :boxplot
            raise NotImplementedError

          when :bubble
            raise NotImplementedError

          when :curve
            context.series.each do |data|
              plot.line(data.xs.to_a, data.ys.to_a)
            end

          when :scatter
            context.series.each do |data|
              plot.scatter(data.xs.to_a, data.ys.to_a)
            end

          when :error_bar
            raise NotImplementedError

          when :hist
            raise NotImplementedError
          end
        plot
      end
    end
  end
end
