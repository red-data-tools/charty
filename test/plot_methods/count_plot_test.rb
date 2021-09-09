class PlotMethodsCountPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("function-call style") do
    # TODO: write tests here
  end

  sub_test_case("DSL style") do
    # TODO: write tests here
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
    def test_count_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.count_plot(data: @data, x: :x)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_count_plot_with_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.count_plot(data: @data, x: :x, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_count_plot_infer_orient(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.count_plot(data: @data, y: :x)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    # TODO: Support numeric data
    def test_count_plot_numeric(data)
      omit("Unsupported yet")
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.count_plot(data: @data, x: :y)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_count_plot_both_x_y(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      assert_raise(ArgumentError.new("Unable to pass both x and y to count_plot")) do
        Charty.count_plot(data: @data, x: :x, y: :y)
      end
    end
  end
end
