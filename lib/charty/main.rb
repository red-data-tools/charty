module Charty
  class Main
    def initialize(frontend)
      @frontend =  case frontend
      when :matplot
        require_relative "matplot"
        Charty::Matplot.new
      when :gruff
        require_relative "gruff"
        Charty::Gruff.new
      when :rubyplot
        require_relative "rubyplot"
        Charty::Rubyplot.new
      else
        raise NotImplementedError
      end
    end

    def table=(data, **kwargs)
      @table = Charty::Table.new(data)
    end

    attr_reader :table

    def to_bar(x, y, **args, &block)
      seriesx, seriesy = *table.to_a(x, y)
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      bar = bar do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_boxplot(x, y, **args, &block)
      serieses = table.to_a(x, y)
      xrange = 0..serieses.size
      yrange = (serieses.flatten.min - 1)..(serieses.flatten.max + 1)
      boxplot = boxplot do
        data serieses
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_bubble(x, y, z, **args, &block)
      seriesx, seriesy, seriesz = *table.to_a(x, y, z)
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      bubble = bubble do
        series seriesx, seriesy, seriesz
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_curve(x, y, **args, &block)
      seriesx, seriesy = *table.to_a(x, y)
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      curve = curve do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_scatter(x, y, **args, &block)
      seriesx, seriesy = *table.to_a(x, y)
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      scatter = scatter do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_errorbar(x, y, **args, &block)
      # TODO: It is not yet decided how to include data including xerror and yerror.
      seriesx, seriesy = *table.to_a(x, y)
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      errorbar = errorbar do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_hst(x, y, **args, &block)
      serieses = table.to_a(x, y)
      xrange = (serieses.flatten.min - 1)..(serieses.flatten.max + 1)
      yrange = 0..serieses[0].size
      hist = hist do
        data serieses
        range x: xrange, y: yrange
        xlabel x
        ylabel y
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

  Series = Struct.new(:xs, :ys, :zs, :xerr, :yerr, :label)

  class RenderContext
    attr_reader :function, :range, :series, :method, :data, :title, :xlabel, :ylabel

    def initialize(method, **args, &block)
      @method = method
      configurator = Configurator.new(**args)
      configurator.instance_eval &block
      (@range, @series, @function, @data, @title, @xlabel, @ylabel) = configurator.to_a
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

      def label(x, y)

      end

      def series(xs, ys=nil, zs=nil, xerr: nil, yerr: nil, label: nil)
        @series << Series.new(xs, ys, zs, xerr, yerr, label)
      end

      def range(range)
        @range = range
      end

      def to_a
        [@range, @series, @function, @data, @title, @xlabel, @ylabel]
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

    def render(filename=nil)
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
