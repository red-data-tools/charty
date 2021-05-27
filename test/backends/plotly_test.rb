class BackendsPlotlyTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("#render") do
    include Charty::RenderingTestHelpers

    sub_test_case("render not for notebook") do
      def test_scatter_plot_render_notebook_plotly
        adapter_name, backend_name = :array, :plotly
        setup_data(adapter_name)
        setup_backend(backend_name)
        plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
        result = render_plot(backend_name, plot, element_id: "foo", notebook: false)
        assert do
          result =~ /<div id="foo" /
        end
      end
    end

    sub_test_case("render for notebook") do
      include Charty::IRubyTestHelper

      def setup
        setup_iruby
      end

      def teardown
        teardown_iruby
      end

      def test_scatter_plot_render_notebook_plotly
        adapter_name, backend_name = :array, :plotly
        setup_data(adapter_name)
        setup_backend(backend_name)
        plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
        result = render_plot(backend_name, plot, notebook: true)
        assert_equal("text/html", result[0])
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
