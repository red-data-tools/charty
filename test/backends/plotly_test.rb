class BackendsPlotlyTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("#render") do
    include Charty::RenderingTestHelpers

    sub_test_case("render not for notebook") do
      sub_test_case("without format") do
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

      sub_test_case("with format: text/html") do
        data(:format, ["text/html", :html, "html"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
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

      sub_test_case("with format: image/png") do
        data(:format, ["image/png", :png, "png"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, element_id: "foo", format: format, notebook: false)
          assert_equal("\x89PNG\x0D\x0A\x1A\x0A".b, result[0,8])
        end
      end

      sub_test_case("with format: image/jpeg") do
        data(:format, ["image/jpeg", :jpeg, "jpeg"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, element_id: "foo", format: format, notebook: false)
          assert_equal(["\xFF\xD8".b, "\xFF\xD9".b],
                       [result[0,2], result[-2,2]])
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

      sub_test_case("without format") do
        def test_scatter_plot_render_notebook_plotly
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, notebook: true)
          assert_equal("text/html", result[0])
        end
      end

      sub_test_case("with format: text/html") do
        data(:format, ["text/html", :html, "html"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, element_id: "foo", format: format, notebook: true)
          assert_equal("text/html", result[0])
        end
      end

      sub_test_case("with format: image/png") do
        data(:format, ["image/png", :png, "png"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, element_id: "foo", format: format, notebook: true)
          assert_equal({
                         mime_type: "image/png",
                         first_8bytes: "\x89PNG\x0D\x0A\x1A\x0A".b
                       },
                       {
                         mime_type: result[0],
                         first_8bytes: result[1][0,8]
                       })
        end
      end

      sub_test_case("with format: image/jpeg") do
        data(:format, ["image/jpeg", :jpeg, "jpeg"])
        def test_scatter_plot_render_notebook_plotly(data)
          format = data[:format]
          adapter_name, backend_name = :array, :plotly
          setup_data(adapter_name)
          setup_backend(backend_name)
          plot = Charty.scatter_plot(data: @data, x: :x, y: :y)
          result = render_plot(backend_name, plot, element_id: "foo", format: format, notebook: true)
          assert_equal({
                         mime_type: "image/jpeg",
                         markers: ["\xFF\xD8".b, "\xFF\xD9".b]
                       },
                       {
                         mime_type: result[0],
                         markers: [result[1][0,2], result[1][-2,2]]
                       })
        end
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
