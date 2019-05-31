require_relative './test_helper'

class PlotterTest < Test::Unit::TestCase
  def test_plotter_use_a_plotter_adapter
    plotter = Charty::Plotter.new :matplot
    adapter = plotter.send(:instance_variable_get, :@plotter_adapter)
    assert_instance_of(Charty::Matplot, adapter)
  end

  sub_test_case("gruff adapter") do
    def test_plotter_use_another_plotter_adapter
      plotter = Charty::Plotter.new :gruff
      adapter = plotter.send(:instance_variable_get, :@plotter_adapter)
      assert_instance_of(Charty::Gruff, adapter)
    end
  end
end
