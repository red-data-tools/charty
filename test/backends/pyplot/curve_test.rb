require_relative "../../test_helper"

class BackendsPyplotCurveTest < Test::Unit::TestCase
  include Helper::Image

  def setup
    @plotter = Charty::Plotter.new(:pyplot)
  end

  def expected_image_path(*components)
    File.join(__dir__, *components)
  end

  test("Integer") do
    curve = @plotter.curve do
      series [0, 1, 2, 3, 4], [10, 40, 20, 90, 70], label: "sample1"
    end
    output = Tempfile.new(["curve", ".png"])
    curve.save(output.path)
    assert_image(expected_image_path("curve_integer.png"),
                 output.path)
  end
end
