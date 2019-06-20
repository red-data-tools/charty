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
      plot = @plot.figure(title: context&.title)
      case context.method
        when :curve
          context.series.each do |data|
            plot.line(data.xs.to_a, data.ys.to_a)
          end
      end
      ::Bokeh::IO::show(plot)
    end
  end
end
