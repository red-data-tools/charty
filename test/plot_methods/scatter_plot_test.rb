class PlotMethodScatterPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("function-call style") do
    def setup
      super

      @x = Array.new(20) {|i| rand(i.to_f) }
      @y = Array.new(20) {|i| rand * @x[i] }
      @data = {x: @x, y: @y}
    end

    sub_test_case("wide-form input") do
      def setup
        omit("TODO")
      end
    end

    sub_test_case("long-form input") do
      sub_test_case("only x and y") do
        def test_scatter_plot
          fig = Charty.scatter_plot(data: @data, x: :x, y: :y)
          assert_equal({
                         x: :x,
                         y: :y,
                         plot_data: Charty::Table.new({
                           x: @x,
                           y: @y,
                         }),
                         variables: {
                           x: :x,
                           y: :y
                         }
                       },
                       {
                         x: fig.x,
                         y: fig.y,
                         plot_data: fig.plot_data,
                         variables: fig.variables,
                       })
        end
      end

      sub_test_case("with color") do
        def setup
          omit("TODO")
        end
      end

      sub_test_case("with style") do
        def setup
          omit("TODO")
        end
      end

      sub_test_case("with size") do
        def setup
          omit("TODO")
        end
      end
    end
  end

  sub_test_case("rendering") do
    include Charty::RenderingTestHelpers

    data(:adapter, [:array], keep: true)
    data(:backend, [:pyplot, :plotly], keep: true)
    def test_scatter_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_scatter_plot_with_numeric_color(data)
      omit("TODO: support numeric variable in color dimension")
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y, color: :d)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_scatter_plot_with_categorical_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_scatter_plot_with_numeric_size(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y, size: :d)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_scatter_plot_with_categorical_size(data)
      omit("TODO: support categorical variable in size dimension")
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y, size: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_scatter_plot_with_style(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.scatter_plot(data: @data, x: :x, y: :y, style: :c)
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
  end
end
