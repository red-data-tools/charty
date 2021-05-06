class PlotMethodsBoxPlotTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("rendering") do
    def setup_data(adapter_name)
      setup_array_data
      case adapter_name
      when :daru
        setup_daru_data
      when :nmatrix
        nmatrix_required
        setup_nmatrix_data
      when :numo
        numo_required
        setup_numo_data
      when :pandas
        pandas_required
        setup_pandas_data
      when :numpy
        pandas_required
        setup_numpy_data
      end
    end

    def setup_array_data
      @data = {
        y: Array.new(100) {|i| rand },
        x: Array.new(100) {|i| ["foo", "bar"][rand(2)] },
        c: Array.new(100) {|i| ["red", "green", "blue"][rand(3)] }
      }
    end

    def setup_daru_data
      @data = Daru::DataFrame.new(@data)
      @data[:x] = @data[:x].to_category
      @data[:c] = @data[:c].to_category
    end

    def setup_nmatrix_data
      @data[:x] = NMatrix[@data[:x], dtype: :object]
      @data[:c] = NMatrix[@data[:c], dtype: :object]
      @data[:y] = NMatrix[*@data[:y]]
    end

    def setup_numo_data
      @data[:y] = Numo::DFloat[*@data[:y]]
      @data[:x] = Numo::RObject[*@data[:x]]
      @data[:c] = Numo::RObject[*@data[:c]]
    end

    def setup_pandas_data
      @data = Pandas::DataFrame.new(data: @data)
    end

    def setup_numpy_data
      @data = {
        y: Numpy.asarray(@data[:y], dtype: Numpy.float64),
        x: Numpy.asarray(@data[:x], dtype: :str),
        c: Numpy.asarray(@data[:c], dtype: :str)
      }
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

    def render_plot(backend_name, plot)
      case backend_name
      when :plotly
        Dir.mktmpdir do |tmpdir|
          plot.save(File.join(tmpdir, "test.html"))
        end
      else
        plot.render
      end
    end

    data(:adapter, [:array, :daru, :numo, :numpy, :pandas], keep: true)
    data(:backend, [:plotly, :pyplot], keep: true)
    def test_box_plot(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.box_plot(data: @data, x: :x, y: :y)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_box_plot_with_color(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.box_plot(data: @data, x: :x, y: :y, color: :c)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_box_plot_infer_orient(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      plot = Charty.box_plot(data: @data, x: :y, y: :x)
      assert_nothing_raised do
        render_plot(backend_name, plot)
      end
    end

    def test_box_plot_h(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      assert_raise(ArgumentError.new("Horizontal orientation requires numeric `x` variable")) do
        Charty.box_plot(data: @data, x: :x, y: :y, orient: :h)
      end
    end

    # TODO: Support the following cases
    data(:adapter, [:nmatrix])
    data(:backend, [:plotly, :pyplot])
    def test_box_plot_unsupported(data)
      adapter_name, backend_name = data.values_at(:adapter, :backend)
      setup_data(adapter_name)
      setup_backend(backend_name)
      assert_raise(NoMethodError) do
        plot = Charty.bar_plot(data: @data, x: :x, y: :y)
        render_plot(backend_name, plot)
      end
    end
  end
end
