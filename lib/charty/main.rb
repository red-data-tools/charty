module Charty
  class Main
    def initialize(frontend)
      @frontend =  case frontend
      when :matplot
        require "charty/matplot"
        Charty::Matplot.new
      when :gruff
        require "charty/gruff"
        Charty::Gruff.new
      when :rubyplot
        require "charty/rubyplot"
        Charty::Rubyplot.new
      else
        raise NotImplementedError
      end
    end

    def bar(**args, &block)
      context = RenderContext.new :bar, **args, &block
      context.apply(@frontend)
    end

    def boxplot(**args, &block)
      context = RenderContext.new :boxplot, **args, &block
      context.apply(@frontend)
    end

    def bubble(**args, &block)
      context = RenderContext.new :bubble, **args, &block
      context.apply(@frontend)
    end

    def curve(**args, &block)
      context = RenderContext.new :curve, **args, &block
      context.apply(@frontend)
    end

    def scatter(**args, &block)
      context = RenderContext.new :scatter, **args, &block
      context.apply(@frontend)
    end

    def errorbar(**args, &block)
      context = RenderContext.new :errorbar, **args, &block
      context.apply(@frontend)
    end

    def hist(**args, &block)
      context = RenderContext.new :hist, **args, &block
      context.apply(@frontend)
    end

    def layout(definition=:horizontal)
      Layout.new(@frontend, definition)
    end
  end

  Series = Struct.new(:xs, :ys, :zs, :label)

  class RenderContext
    attr_reader :function, :range, :series, :method, :data, :title, :xlabel, :ylabel, :xerr, :yerr

    def initialize(method, **args, &block)
      @method = method
      configurator = Configurator.new(**args)
      configurator.instance_eval &block
      (@range, @series, @function, @data, @title, @xlabel, @ylabel, @xerr, @yerr) = configurator.to_a
    end

    class Configurator
      def initialize(**args)
        @args = args
        @series = []
      end

      def function(&block)
        @function = block
      end

      def data(data)
        @data = data
      end

      def title(title)
        @title = title
      end

      def xlabel(xlabel)
        @xlabel = xlabel
      end

      def ylabel(ylabel)
        @ylabel = ylabel
      end

      def xerr(xerr)
        @xerr = xerr
      end

      def yerr(yerr)
        @yerr = yerr
      end

      def label(x, y)

      end

      def series(xs, ys=nil, zs=nil, label: nil)
        @series << Series.new(xs, ys, zs, label)
      end

      def range(range)
        @range = range
      end

      def to_a
        [@range, @series, @function, @data, @title, @xlabel, @ylabel, @xerr, @yerr]
      end

      def method_missing(method, *args)
        if (@args.has_key?(method))
          @args[name]
        else
          super
        end
      end
    end

    def range_x
      @range[:x]
    end

    def range_y
      @range[:y]
    end

    def render(filename="")
      @frontend.render(self, filename)
    end

    def apply(frontend)
      case
        when !@series.empty?
          frontend.series = @series
        when @function
          linspace = Linspace.new(@range[:x], 100)
          # TODO: set label with function
          # TODO: set ys to xs when gruff curve with function
          @series << Series.new(linspace.to_a, linspace.map{|x| @function.call(x) }, label: "function" )
      end

      @frontend = frontend
      self
    end
  end
end
