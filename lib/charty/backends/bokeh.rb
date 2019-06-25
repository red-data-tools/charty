require 'bokeh'

module Charty
  class Bokeh < PlotterAdapter
    Name = "bokeh"

    def initialize
      @plot = ::Bokeh::Plotting
    end

    def series=(series)
      @series = series
    end

    def render(context, filename)
      plot = plot(context)
      save(plot, context, filename)
      ::Bokeh::IO::show(plot)
    end

    def save(plot, context, filename)
      if filename
        ::Bokeh::IO::save(plot, filename)
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
            plot.vbar(data.xs.to_a, nil, data.ys.to_a)
          end

        when :barh
          context.series.each do |data|
            context.series.each do |data|
              plot.hbar(data.xs.to_a, nil, data.ys.to_a)
            end
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
