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

    def range=(range)
      @range = range
    end

    def render(type)
      @plot.xlim(@range[:x].begin, @range[:x].end)
      @plot.ylim(@range[:y].begin, @range[:y].end)

      case type
      when :curve
        @plot.plot(@series.xs, @series.ys)
      when :scatter
        @plot.plot(@series.xs, @series.ys, "o")
      end
      @plot.show
    end
  end
end
