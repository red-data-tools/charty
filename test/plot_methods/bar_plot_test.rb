class PlotMethodsBarPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("function-call style") do
    test("given x and y") do
      x = [1, 2, 3, 4, 5]
      y = [10, 20, 30, 25, 15]
      fig = Charty.bar_plot(x: x, y: y)
      assert_instance_of(Charty::Plotters::BarPlotter, fig)
      assert_equal({
                     x: Charty::Vector.new(x),
                     y: Charty::Vector.new(y),
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
                     data: {
                       x: Charty::Vector.new(data[:x]),
                       y: Charty::Vector.new(data[:y]),
                     },
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
                     x: Charty::Vector.new(x),
                     y: Charty::Vector.new(y),
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
                     data: {
                       x: Charty::Vector.new(data[:x]),
                       y: Charty::Vector.new(data[:y]),
                     },
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
    include Charty::RenderingTestHelpers

    def setup_array_data
      @data = {
        y: Array.new(100) {|i| rand },
        x: Array.new(100) {|i| ["foo", "bar"][rand(2)] },
        c: Array.new(100) {|i| ["red", "blue", "green"][rand(3)] }
      }
    end

    def setup_arrow_data
      @data = Arrow::Table.new(@data)
    end

    def setup_daru_data
      @data = Daru::DataFrame.new(@data)
      @data[:x] = @data[:x].to_category
      @data[:c] = @data[:c].to_category
    end

    def setup_nmatrix_data
      omit("TODO: Support NMatrix")
      @data[:x] = NMatrix.new([100], @data[:x], dtype: :object)
      @data[:c] = NMatrix.new([100], @data[:c], dtype: :object)
      @data[:y] = NMatrix.new([100], @data[:y], dtype: :float64)
    end

    def setup_numo_data
      @data[:y] = Numo::DFloat[*@data[:y]]
    end

    def setup_pandas_data
      @data = Pandas::DataFrame.new(data: @data)
    end

    def setup_numpy_data
      @data[:x] = Numpy.asarray(@data[:x], dtype: :str)
      @data[:c] = Numpy.asarray(@data[:c], dtype: :str)
      @data[:y] = Numpy.asarray(@data[:y])
    end

    data(:adapter,
         [:array, :arrow, :daru, :numo, :nmatrix, :numpy, :pandas],
         keep: true)
    data(:backend, [:plotly, :pyplot], keep: true)
    def test_bar_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(data: @data, x: :x, y: :y)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_bar_plot_with_vectors(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(x: @data[:x].to_a, y: @data[:y].to_a)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_bar_plot_with_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(data: @data, x: :x, y: :y, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_bar_plot_infer_orient(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(data: @data, x: :y, y: :x)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_bar_plot_h(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      assert_raise(ArgumentError.new("Horizontal orientation requires numeric `x` variable")) do
        Charty.bar_plot(data: @data, x: :x, y: :y, orient: :h)
      end
    end

    def test_bar_plot_sd(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.bar_plot(data: @data, x: :x, y: :y, ci: :sd)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end
  end
end
