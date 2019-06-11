require_relative './test_helper'

class PlotterTest < Test::Unit::TestCase
  def test_plotter_use_a_plotter_adapter
    plotter = Charty::Plotter.new :pyplot
    adapter = plotter.send(:instance_variable_get, :@plotter_adapter)
    assert_instance_of(Charty::PyPlot, adapter)
  end
end
