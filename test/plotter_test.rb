class PlotterTest < Test::Unit::TestCase
  def setup
    @plotter = Charty::Plotter.new(:plotly)
    @data = {
              foo: [1, 2, 3, 4, 5, 6, 7],
              square: [1, 4, 9, 16, 25, 36, 49],
              cubic: [1, 8, 27, 64, 125, 216, 343],
            }
  end

  test("#table=") do
    @plotter.table = @data
    assert_equal(Charty::Vector.new(@data[:foo]),
                 @plotter.table[:foo].data)
    assert_equal(Charty::Vector.new(@data[:square]),
                 @plotter.table[:square].data)
    assert_equal(Charty::Vector.new(@data[:cubic]),
                 @plotter.table[:cubic].data)
  end

  test("#to_bar") do
    @plotter.table = @data
    context = @plotter.to_bar(:foo, :cubic)
    assert_kind_of(Charty::RenderContext,
                   context)
    assert_equal(@data[:foo],
                 context.series[0].xs.to_a)
    assert_equal(@data[:cubic],
                 context.series[0].ys.to_a)
  end
end
