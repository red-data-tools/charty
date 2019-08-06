module Charty
  class Plotter
    def initialize(adapter_name)
      @plotter_adapter =  PlotterAdapter.create(adapter_name)
    end

    def table=(data, **kwargs)
      @table = Charty::Table.new(data)
    end

    attr_reader :table

    def to_bar(x, y, **args, &block)
      seriesx = table[x]
      seriesy = table[y]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      bar do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_barh(x, y, **args, &block)
      seriesx = table[x]
      seriesy = table[y]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      barh do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_box_plot(x, y, **args, &block)
      serieses = [table[x], table[y]]
      xrange = 0..serieses.size
      yrange = (serieses.flatten.min - 1)..(serieses.flatten.max + 1)
      box_plot do
        data serieses
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_bubble(x, y, z, **args, &block)
      seriesx = table[x]
      seriesy = table[y]
      seriesz = table[z]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      bubble do
        series seriesx, seriesy, seriesz
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_curve(x, y, **args, &block)
      seriesx = table[x]
      seriesy = table[y]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      curve do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_scatter(x, y, **args, &block)
      seriesx = table[x]
      seriesy = table[y]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      scatter do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_error_bar(x, y, **args, &block)
      # TODO: It is not yet decided how to include data including xerror and yerror.
      seriesx = table[x]
      seriesy = table[y]
      xrange = (seriesx.min)..(seriesx.max)
      yrange = (seriesy.min)..(seriesy.max)
      error_bar do
        series seriesx, seriesy
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def to_hst(x, y, **args, &block)
      serieses = [table[x], table[y]]
      xrange = (serieses.flatten.min - 1)..(serieses.flatten.max + 1)
      yrange = 0..serieses[0].size
      hist do
        data serieses
        range x: xrange, y: yrange
        xlabel x
        ylabel y
      end
    end

    def bar(**args, &block)
      context = RenderContext.new :bar, **args, &block
      context.apply(@plotter_adapter)
    end

    def barh(**args, &block)
      context = RenderContext.new :barh, **args, &block
      context.apply(@plotter_adapter)
    end

    def box_plot(**args, &block)
      context = RenderContext.new :box_plot, **args, &block
      context.apply(@plotter_adapter)
    end

    def bubble(**args, &block)
      context = RenderContext.new :bubble, **args, &block
      context.apply(@plotter_adapter)
    end

    def curve(**args, &block)
      context = RenderContext.new :curve, **args, &block
      context.apply(@plotter_adapter)
    end

    def scatter(**args, &block)
      context = RenderContext.new :scatter, **args, &block
      context.apply(@plotter_adapter)
    end

    def error_bar(**args, &block)
      context = RenderContext.new :error_bar, **args, &block
      context.apply(@plotter_adapter)
    end

    def hist(**args, &block)
      context = RenderContext.new :hist, **args, &block
      context.apply(@plotter_adapter)
    end

    def layout(definition=:horizontal)
      Layout.new(@plotter_adapter, definition)
    end
  end

  Series = Struct.new(:xs, :ys, :zs, :xerr, :yerr, :label)

  class RenderContext
    attr_reader :function, :range, :series, :method, :data, :title, :xlabel, :ylabel, :labels

    def initialize(method, **args, &block)
      @method = method
      configurator = Configurator.new(**args)
      configurator.instance_eval(&block)
      # TODO: label も外から付けられた方がよさそう
      (@range, @series, @function, @data, @title, @xlabel, @ylabel, @labels) = configurator.to_a
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

      def labels(labels)
        @labels = labels
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
        [@range, @series, @function, @data, @title, @xlabel, @ylabel, @labels]
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
      @plotter_adapter.render(self, filename)
    end

    def save(filename=nil)
      @plotter_adapter.save(self, filename)
    end

    def apply(plotter_adapter)
      case
        when !@series.empty?
          plotter_adapter.series = @series
        when @function
          linspace = Linspace.new(@range[:x], 100)
          # TODO: set label with function
          # TODO: set ys to xs when gruff curve with function
          @series << Series.new(linspace.to_a, linspace.map{|x| @function.call(x) }, label: "function" )
      end

      @plotter_adapter = plotter_adapter
      self
    end
  end
end
