require_relative "../test_helper"

class PlotMethodsBarPlotTest < Test::Unit::TestCase
  sub_test_case("function-call style") do
    test("given x and y") do
      x = [1, 2, 3, 4, 5]
      y = [10, 20, 30, 25, 15]
      fig = Charty.bar_plot(x, y)
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal(x, fig.x)
      assert_equal(y, fig.y)
      assert_equal(nil, fig.color)
      assert_equal(nil, fig.data)
      assert_equal(nil, fig.palette)
      assert_equal(x, fig.group_names)
      assert_equal(y.map{|v| [v] }, fig.plot_data)
    end

    test("given x and y as names, and data as a hash table") do
      data = {
        x: [1, 2, 3, 4, 5],
        y: [10, 20, 30, 25, 15]
      }
      fig = Charty.bar_plot(:x, :y, data: data)
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal(:x, fig.x)
      assert_equal(:y, fig.y)
      assert_equal(nil, fig.color)
      assert_equal(data, fig.data.raw_data)
      assert_equal(nil, fig.palette)
      assert_equal(data[:x], fig.group_names)
      assert_equal(data[:y].map{|v| [v] }, fig.plot_data)
    end
  end

  sub_test_case("DSL style") do
    test("given x and y") do
      x = [1, 2, 3, 4, 5]
      y = [10, 20, 30, 25, 15]
      fig = Charty.bar_plot do |pl|
        pl.x = x
        pl.y = y
      end
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal(x, fig.x)
      assert_equal(y, fig.y)
      assert_equal(nil, fig.color)
      assert_equal(nil, fig.data)
      assert_equal(nil, fig.palette)
      assert_equal(x, fig.group_names)
      assert_equal(y.map{|v| [v] }, fig.plot_data)
    end

    test("given x and y as names, and data as a hash table") do
      data = {
        x: [1, 2, 3, 4, 5],
        y: [10, 20, 30, 25, 15]
      }
      fig = Charty.bar_plot do |pl|
        pl.x = :x
        pl.y = :y
        pl.data = data
      end
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal(:x, fig.x)
      assert_equal(:y, fig.y)
      assert_equal(nil, fig.color)
      assert_equal(data, fig.data.raw_data)
      assert_equal(nil, fig.palette)
      assert_equal(data[:x], fig.group_names)
      assert_equal(data[:y].map{|v| [v] }, fig.plot_data)
    end
  end
end
