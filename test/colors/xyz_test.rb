require_relative "../test_helper"

class ColorsXYZTest < Test::Unit::TestCase
  sub_test_case("#luv_components") do
    test("on ITU-R BT.709 D65 white point") do
      l, u, v = Charty::Colors::XYZ.from_rgb(0r, 0r, 0r).luv_components(Charty::Colors::WHITE_POINT_D65)
      assert_in_delta(0, l)
      assert_in_delta(0, u)
      assert_in_delta(0, v)
    end
  end
end
