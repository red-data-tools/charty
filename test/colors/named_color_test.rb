require_relative '../test_helper'

class ColorsNamedColorTest < Test::Unit::TestCase
  sub_test_case("Charty::Colors[]") do
    Charty::Colors::ColorData::DEFAULT_COLOR_CYCLE.each_with_index do |c, i|
      name = "C#{i}"
      expected = Charty::Colors::RGB.parse(c)
      data("Color cycle: #{name}=#{c}", [name, expected])
    end
    Charty::Colors::ColorData::BASE_COLORS.each do |name, (r, g, b)|
      expected = Charty.RGB(r, g, b)
      data("Base color: #{name}=(#{r}, #{g}, #{b})", [name, expected])
    end
    Charty::Colors::ColorData::TABLEAU_COLORS.each do |name, hex_string|
      expected = Charty::Colors::RGB.parse(hex_string)
      data("Tableau color: #{name}=#{hex_string}", [name, expected])
      if name.include? "gray"
        name = name.sub("gray", "grey")
        data("Tableau color: #{name}=#{hex_string}", [name, expected])
      end
    end
    Charty::Colors::ColorData::CSS4_COLORS.each do |name, hex_string|
      expected = Charty::Colors::RGB.parse(hex_string)
      data("CSS4 color: #{name}=#{hex_string}", [name, expected])
    end
    Charty::Colors::ColorData::XKCD_COLORS.each do |name, hex_string|
      expected = Charty::Colors::RGB.parse(hex_string)
      data("XKCD color: #{name}=#{hex_string}", [name, expected])
      if name.include? "grey"
        name = name.sub("grey", "gray")
        data("Tableau color: #{name}=#{hex_string}", [name, expected])
      end
    end
    def test_lookup_named_color(data)
      name, expected = data
      assert_equal(expected, Charty::Colors[name])
    end
  end

  test("Charty::Colors::NamedColors.nth_color?") do
    assert do
      Charty::Colors::NamedColors.nth_color?("C1")
    end
  end
end
