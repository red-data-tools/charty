class PlotMethodHistPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("rendering") do
    include Charty::RenderingTestHelpers

    data(:adapter, [:array, :arrow])
    data(:backend, [:pyplot, :plotly])
    def test_hist_plot_with_flat_vectors(data)
      backend_name = data[:backend]
      setup_backend(backend_name)
      data = Array.new(500) { rand }
      plot = Charty.hist_plot(data: data)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    sub_test_case("wide form") do
      data(:adapter, [:array, :arrow, :pandas], keep: true)
      data(:backend, [:pyplot, :plotly], keep: true)
      def test_hist_plot_with_wide_form(data)
        adapter_name, backend_name = data.values_at(:adapter, :backend)
        setup_data(adapter_name)
        setup_backend(backend_name)
        plot = Charty.hist_plot(data: @data, x_label: "Foo Bar")
        assert_nothing_raised do
          assert_equal("Foo Bar", plot.x_label)
          render_plot(backend_name, plot)
        end
      end

      def setup_array_data
        @data = @array_data = {
          red: Array.new(100) {|i| rand },
          blue: Array.new(100) {|i| rand + 1},
          green: Array.new(100) {|i| rand + 2 },
        }
      end

      def setup_arrow_data
        @data = Arrow::Table.new(@array_data)
      end

      def setup_pandas_data
        pandas_required
        @data = Pandas::DataFrame.new(data: @array_data)
        @data[:red] = @data[:red].astype("float64")
        @data[:blue] = @data[:blue].astype("float64")
        @data[:green] = @data[:green].astype("float64")
      end
    end

    data(:adapter, [:array, :arrow, :pandas], keep: true)
    data(:backend, [:pyplot, :plotly], keep: true)
    def test_hist_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.hist_plot(data: @data, x: :a)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_hist_plot_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
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

    def setup_arrow_data
      @data = Arrow::Table.new(
        a: @array_data[:a],
        c: Arrow::Array.new(@array_data[:c]).dictionary_encode
      )
    end

    def setup_pandas_data
      pandas_required
      @data = Pandas::DataFrame.new(data: @array_data)
      @data[:a] = @data[:a].astype("float64")
      @data[:c] = @data[:c].astype("category")
    end
  end
end
