require_relative './test_helper'

class PlotterTest < Test::Unit::TestCase
  def setup
    @plotter = Charty::Plotter.new(:pyplot)
    assert_instance_of(Charty::PyPlot,
                       @plotter.instance_variable_get(:@plotter_adapter))

    @data = {
              foo: [1, 2, 3, 4, 5, 6, 7],
              square: [1, 4, 9, 16, 25, 36, 49],
              cubic: [1, 8, 27, 64, 125, 216, 343],
            }
  end

  test("#table=") do
    @plotter.table = @data
    assert_equal(@data[:foo],
                 @plotter.table[:foo])
    assert_equal(@data[:square],
                 @plotter.table[:square])
    assert_equal(@data[:cubic],
                 @plotter.table[:cubic])
  end

  test("#to_bar") do
    @plotter.table = @data
    context = @plotter.to_bar(:foo, :cubic)
    assert_kind_of(Charty::RenderContext,
                   context)
    assert_equal(@data[:foo],
                 context.series[0].xs)
    assert_equal(@data[:cubic],
                 context.series[0].ys)
  end
end
