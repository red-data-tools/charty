module RedVisualizer
  class Main
    def initialize(frontend)
      @frontend = frontend
    end

    def curve(&block)
      context = RenderContext.new &block
      context.apply(@frontend)
    end
  end

  Series = Struct.new(:xs, :ys)

  class RenderContext
    def initialize(&block)
      @series = []
      self.instance_eval &block
    end

    def function(&block)
      @function = block
    end

    def range(range)
      @range = range
    end

    def render
      @frontend.render
    end

    def apply(frontend)
      case
        when @function
          x_range = @range[:x]
          step = (x_range.end - x_range.begin).to_f / 100
          frontend.series = Series.new(x_range.step(step).to_a, x_range.step(step).map{|x| @function.call(x) })
      end
      @frontend = frontend
      self
    end
  end
end
