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
  end
end
