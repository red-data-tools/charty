require_relative './test_helper'

class PlotterTest < Test::Unit::TestCase
  def setup
    load File.expand_path('../lib/charty/matplot.rb', __dir__)
  end

  def teardown
    Charty.send(:remove_const, :Matplot)
    Charty::PlotterAdapter.send(:instance_variable_set, :@adapters, [])
  end

  def test_plotter_use_a_plotter_adapter
    plotter = Charty::Plotter.new :matplot
    adapter = plotter.send(:instance_variable_get, :@plotter_adapter)
    assert_instance_of(Charty::Matplot, adapter)
  end

  def test_error_if_plotter_adapter_is_not_loaded
    assert_raise_kind_of(Charty::AdapterNotLoadedError) do
      Charty::Plotter.new(:gruff)
    end
  end

  sub_test_case("gruff adapter") do
    def setup
      load File.expand_path('../lib/charty/gruff.rb', __dir__)
    end

    def teardown
      Charty.send(:remove_const, :Gruff)
      Charty::PlotterAdapter.send(:instance_variable_set, :@adapters, [])
    end

    def test_plotter_use_another_plotter_adapter
      plotter = Charty::Plotter.new :gruff
      adapter = plotter.send(:instance_variable_get, :@plotter_adapter)
      assert_instance_of(Charty::Gruff, adapter)
    end
  end
end
