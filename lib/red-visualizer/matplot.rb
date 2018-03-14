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

    def render
      @plot.plot(@series.xs, @series.ys)
      @plot.show
    end
  end
end
