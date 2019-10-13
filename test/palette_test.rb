require_relative "test_helper"

require "enumerable/statistics"

class PaletteTest < Test::Unit::TestCase
  include TestHelper

  sub_test_case(".default") do
    test("the initial value") do
      assert_equal(Charty::Palette.new("deep"), Charty::Palette.default)
    end
  end

  test(".default=") do
    begin
      save = Charty::Palette.default
      palette = Charty::Palette.new("colorblind")
      Charty::Palette.default = palette
      assert_same(palette, Charty::Palette.default)
    ensure
      Charty::Palette.default = save
    end
  end

  test("array palette") do
    palette = Charty::Palette.new(["red", "green", "blue"])
    assert_equal(nil, palette.name)
    assert_equal(3, palette.n_colors)
    assert_equal(["red", "green", "blue"], palette.colors)
  end

  sub_test_case("seaborn's named palette") do
    test("deep") do
      palette = Charty::Palette.new("deep")
      assert_equal("deep", palette.name)
      assert_equal(Charty::Palette::QUAL_PALETTE_SIZES["deep"],
                   palette.n_colors)
      assert_equal(Charty::Palette::SEABORN_PALETTES["deep"].map {|c|
                     Charty::Colors::RGB.parse(c)
                   },
                   palette.colors)
    end

    test("pastel6") do
      palette = Charty::Palette.new("pastel6")
      assert_equal("pastel6", palette.name)
      assert_equal(Charty::Palette::QUAL_PALETTE_SIZES["pastel6"],
                   palette.n_colors)
      assert_equal(Charty::Palette::SEABORN_PALETTES["pastel6"].map {|c|
                     Charty::Colors::RGB.parse(c)
                   },
                   palette.colors)
    end
  end

  test("HSL color palette") do
    assert_equal(6,
                 Charty::Palette.new("hsl").n_colors)
  end

  test("HUSL color palette") do
    omit("Not implemented yet")
    assert_equal(6,
                 Charty::Palette.new("husl").n_colors)
  end

  test(".hsl_colors") do
    palette1 = Charty::Palette.hsl_colors(6, h: 0)
    palette2 = Charty::Palette.hsl_colors(6, h: 360/2r)
    palette2 = palette2[3..-1] + palette2[0...3]
    palette1.zip(palette2).each do |c1, c2|
      assert_in_delta(c1.h, c2.h, 1e-6)
      assert_in_delta(c1.s, c2.s, 1e-6)
      assert_in_delta(c1.l, c2.l, 1e-6)
    end

    palette_dark = Charty::Palette.hsl_colors(5, l: 0.2)
    palette_bright = Charty::Palette.hsl_colors(5, l: 0.8)
    palette_dark.zip(palette_bright).each do |c1, c2|
      s1 = c1.to_rgb.components.sum
      s2 = c2.to_rgb.components.sum
      assert do
        s1 < s2
      end
    end

    palette_flat = Charty::Palette.hsl_colors(5, s: 0.1)
    palette_bold = Charty::Palette.hsl_colors(5, s: 0.9)
    palette_flat.zip(palette_bold).each do |c1, c2|
      s1 = c1.to_rgb.components.stdev(population: true).to_f
      s2 = c2.to_rgb.components.stdev(population: true).to_f
      assert do
        s1 < s2
      end
    end
  end

  test(".husl_colors") do
    palette1 = Charty::Palette.husl_colors(6, h: 0)
    palette2 = Charty::Palette.husl_colors(6, h: 360/2r)
    palette2 = palette2[3..-1] + palette2[0...3]
    palette1.zip(palette2).each do |c1, c2|
      assert_in_delta(c1.h, c2.h, 1e-6)
      assert_in_delta(c1.s, c2.s, 1e-6)
      assert_in_delta(c1.l, c2.l, 1e-6)
    end

    palette_dark = Charty::Palette.husl_colors(5, l: 0.2)
    palette_bright = Charty::Palette.husl_colors(5, l: 0.8)
    palette_dark.zip(palette_bright).each do |c1, c2|
      s1 = c1.to_rgb.components.sum
      s2 = c2.to_rgb.components.sum
      assert do
        s1 < s2
      end
    end

    palette_flat = Charty::Palette.husl_colors(5, s: 0.1)
    palette_bold = Charty::Palette.husl_colors(5, s: 0.9)
    palette_flat.zip(palette_bold).each do |c1, c2|
      s1 = c1.to_rgb.components.stdev
      s2 = c2.to_rgb.components.stdev
      assert do
        s1 < s2
      end
    end
  end

  test(".cubehelix_colors") do
    omit("Not implemented yet")
  end

  sub_test_case(".matplotlib_colors") do
    test("Set3") do
      omit("Not implemented yet")
      palette = Charty::Palette.new("Set3")
      assert_equal("Set3", palette.name)
      assert_equal(Charty::Palette::QUAL_PALETTE_SIZES["Set3"],
                   palette.n_colors)
      assert_equal(Charty::Palette::SEABORN_PALETTES["Set3"].map {|c|
                     Charty::Colors::RGB.parse(c)
                   },
                   palette.colors)
    end
  end

  test("desaturation feature") do
    desaturated_colors = Charty::Palette.new(["#ff0000", "#00ff0099"], desaturate_factor: 0.8).colors
    assert_near(Charty::Colors::HSL.new(0, 0.8r, 0.5r).to_rgb,
                desaturated_colors[0])
    assert_near(Charty::Colors::HSLA.new(120r, 0.8r, 0.5r, 0x99/255r).to_rgba,
                desaturated_colors[1])
  end
end
