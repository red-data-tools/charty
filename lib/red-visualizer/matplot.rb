require 'matplotlib/pyplot'
require 'matplotlib/iruby'

module RedVisualizer
  class Matplot
    def initialize
      @plot = Matplotlib::Pyplot
    end

    def self.notebook
      Matplotlib::IRuby.activate

      self.new
    end

    def label(x, y)

    end

    def series=(series)
      @series = series
    end

    def render(context)
      @plot.xlim(context.range_x.begin, context.range_x.end)
      @plot.ylim(context.range_y.begin, context.range_y.end)

      case context.method
      when :curve
        @plot.plot(context.series.xs, context.series.ys)
      when :scatter
        @plot.plot(context.series.xs, context.series.ys, ".")
      end
      @plot.show
    end
  end
end
