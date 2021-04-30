class PlotMethodsBarPlotTest < Test::Unit::TestCase
  sub_test_case("function-call style") do
    test("given x and y") do
      x = [1, 2, 3, 4, 5]
      y = [10, 20, 30, 25, 15]
      fig = Charty.bar_plot(x: x, y: y)
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal({
                     x: x,
                     y: y,
                     color: nil,
                     data: nil,
                     palette: nil,
                     group_names: x,
                     plot_data: y.map {|v| [v] }
                   },
                   {
                     x: fig.x,
                     y: fig.y,
                     color: fig.color,
                     data: fig.data,
                     palette: fig.palette,
                     group_names: fig.group_names.to_a,
                     plot_data: fig.plot_data.map(&:to_a)
                   })
    end

    test("given x and y as names, and data as a hash table") do
      data = {
        x: [1, 2, 3, 4, 5],
        y: [10, 20, 30, 25, 15]
      }
      fig = Charty.bar_plot(x: :x, y: :y, data: data)
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal({
                     x: :x,
                     y: :y,
                     color: nil,
                     data: data,
                     palette: nil,
                     group_names: data[:x],
                     plot_data: data[:y].map {|v| [v] }
                   },
                   {
                     x: fig.x,
                     y: fig.y,
                     color: fig.color,
                     data: fig.data.raw_data,
                     palette: fig.palette,
                     group_names: fig.group_names.to_a,
                     plot_data: fig.plot_data.map(&:to_a)
                   })
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
      assert_equal({
                     x: x,
                     y: y,
                     color: nil,
                     data: nil,
                     palette: nil,
                     group_names: x,
                     plot_data: y.map {|v| [v] }
                   },
                   {
                     x: fig.x,
                     y: fig.y,
                     color: fig.color,
                     data: fig.data,
                     palette: fig.palette,
                     group_names: fig.group_names.to_a,
                     plot_data: fig.plot_data.map(&:to_a)
                   })
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
      assert_equal({
                     x: :x,
                     y: :y,
                     color: nil,
                     data: data,
                     palette: nil,
                     group_names: data[:x],
                     plot_data: data[:y].map {|v| [v] }
                   },
                   {
                     x: fig.x,
                     y: fig.y,
                     color: fig.color,
                     data: fig.data.raw_data,
                     palette: fig.palette,
                     group_names: fig.group_names.to_a,
                     plot_data: fig.plot_data.map(&:to_a)
                   })
    end
  end

  sub_test_case("rendering") do
    def setup_data(adapter_name)
      case adapter_name
      when :pandas
        if defined?(Pandas::DataFrame)
          setup_pandas_data
        else
          pandas_required
        end
      end
    end

    def setup_pandas_data
      @data = Pandas::DataFrame.new(
        data: {
          y: Array.new(100) {|i| rand },
          x: Array.new(100) {|i| ["foo", "bar"][rand(2)] }
        }
      )
    end

    def setup_backend(backend_name)
      case backend_name
      when :pyplot
        if defined?(Matplotlib)
          setup_pyplot_backend
        else
          matplotlib_required
        end
      end
      Charty::Backends.use(backend_name)
    end

    def setup_pyplot_backend
      require "matplotlib"
      Matplotlib.use("agg")
    end

    data(:adapter, [:pandas])
    data(:backend, [:pyplot])
    def test_bar_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(data: @data, x: :x, y: :y)
      assert_nothing_raised do
        plot.render
      end
    end
  end
end
