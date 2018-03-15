module RedVisualizer
  class Main
    def initialize(frontend)
      @frontend = frontend
    end

    def curve(&block)
      context = RenderContext.new :curve, &block
      context.apply(@frontend)
    end

    def scatter(&block)
      context = RenderContext.new :scatter, &block
      context.apply(@frontend)
    end

    def layout(definition=:horizontal)
      Layout.new(@frontend, definition)
    end
  end

  Series = Struct.new(:xs, :ys)

  class RenderContext
    attr_reader :function, :range, :series, :method

    def initialize(method, &block)
      @method = method
      configurator = Configurator.new
      configurator.instance_eval &block
      (@range, @series, @function) = configurator.to_a
    end

    class Configurator
      def function(&block)
        @function = block
      end

      def series(xs, ys)
        @series = Series.new(xs, ys)
      end

      def range(range)
        @range = range
      end

      def to_a
        [@range, @series, @function]
      end
    end

    def range_x
      @range[:x]
    end

    def range_y
      @range[:y]
    end

    def render
      @frontend.render(self)
    end

    def apply(frontend)
      case
        when @series
          frontend.series = @series
        when @function
          x_range = @range[:x]
          step = (x_range.end - x_range.begin).to_f / 100
          @series = Series.new(x_range.step(step).to_a, x_range.step(step).map{|x| @function.call(x) })
      end

      @frontend = frontend
      self
    end
  end
end
