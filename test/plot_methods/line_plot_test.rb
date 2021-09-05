class PlotMethodLinePlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("rendering") do
    include Charty::RenderingTestHelpers

    def test_line_plot_with_flat_vector
      backend_name = :pyplot
      setup_backend(backend_name)
      plot = Charty.line_plot(data: [1, 2, 3, 4, 5])
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_vectors
      backend_name = :pyplot
      setup_backend(backend_name)
      plot = Charty.line_plot(x: [1, 2, 3, 4, 5], y: [1, 4, 2, 3, 5])
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    data(:adapter, [:array, :arrow], keep: true)
    data(:backend, [:pyplot, :plotly], keep: true)
    def test_line_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_numeric_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, color: :d)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_categorical_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_numeric_size(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, size: :d)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_categorical_size(data)
      omit("TODO: support categorical variable in size dimension")
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, size: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_with_style(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, style: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_error_bar_sd(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, error_bar: :sd)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_line_plot_xy_log(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.line_plot(data: @data, x: :x, y: :y, x_scale: :log, y_scale: :log)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def setup_array_data
      @data = {
        y: Array.new(100) {|i| rand },
        x: Array.new(100) {|i| rand(100) },
        c: Array.new(100) {|i| ["red", "blue", "green"][rand(3)] },
        d: Array.new(100) {|i| rand(10..50) }
      }
    end

    def setup_arrow_data
      @data = Arrow::Table.new(y: @data[:y],
                               x: @data[:x],
                               c: Arrow::Array.new(@data[:c]).dictionary_encode,
                               d: @data[:d])
    end
  end
end
