module RedVisualizer
  class Main
    def initialize(frontend)
      @frontend = frontend
    end

    def curve(&block)
      context = RenderContext.new &block
      context.apply(:curve, @frontend)
    end

    def scatter(&block)
      context = RenderContext.new &block
      context.apply(:scatter, @frontend)
    end
  end

  Series = Struct.new(:xs, :ys)

  class RenderContext
    def initialize(&block)
      self.instance_eval &block
    end

    def function(&block)
      @function = block
    end

    def series(xs, ys)
      @series = Series.new(xs, ys)
    end

    def range(range)
      @range = range
    end

    def render
      @frontend.render(@type)
    end

    def apply(type, frontend)
      case
        when @series
          frontend.series = @series
        when @function
          x_range = @range[:x]
          step = (x_range.end - x_range.begin).to_f / 100
          frontend.series = Series.new(x_range.step(step).to_a, x_range.step(step).map{|x| @function.call(x) })
      end

      frontend.range = @range
      @type = type
      @frontend = frontend
      self
    end
  end
end
