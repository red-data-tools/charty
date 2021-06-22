class PlotMethodHistPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("rendering") do
    include Charty::RenderingTestHelpers

    data(:adapter, [:array], keep: true)
    data(:backend, [:pyplot, :plotly], keep: true)
    def test_hist_plot_with_flat_vectors(data)
      backend_name = data[:backend]
      omit("pyplot is not supported yet") if backend_name == :pyplot
      setup_backend(backend_name)
      data = Array.new(500) { rand }
      plot = Charty.hist_plot(data: data)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    data(:adapter, [:array, :pandas], keep: true)
    data(:backend, [:pyplot, :plotly], keep: true)
    def test_hist_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      omit("pyplot is not supported yet") if backend_name == :pyplot
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.hist_plot(data: @data, x: :a)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_hist_plot_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      omit("pyplot is not supported yet") if backend_name == :pyplot
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.hist_plot(data: @data, x: :a, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def setup_array_data
      @data = @array_data = {
        a: Array.new(100) {|i| rand },
        c: Array.new(100) {|i| ["red", "blue", "green"][rand(3)] },
      }
    end

    def setup_pandas_data
      @data = Pandas::DataFrame.new(data: @array_data)
      @data[:a] = @data[:a].astype("float64")
      @data[:c] = @data[:c].astype("category")
    end
  end
end
