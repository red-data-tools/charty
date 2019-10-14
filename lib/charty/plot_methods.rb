module Charty
  module PlotMethods
    # Show the given data as rectangular bars.
    #
    # @param x
    # @param y
    # @param color
    # @param data
    def bar_plot(x=nil, y=nil, color=nil, **options, &block)
      Plotters::BarPlotter.new(x, y, color, **options, &block)
    end

    def box_plot(x=nil, y=nil, color=nil, **options, &block)
      Plotters::BoxPlotter.new(x, y, color, **options, &block)
    end
  end

  extend PlotMethods
end
