require_relative '../test_helper'

class ColorsHSLTest < Test::Unit::TestCase
  sub_test_case(".new") do
    test("with integer values") do
      c = Charty::Colors::HSL.new(1, 128, 255)
      assert_equal(1r, c.hue)
      assert_equal(128/255r, c.saturation)
      assert_equal(255/255r, c.lightness)

      c = Charty::Colors::HSL.new(-1, 128, 255)
      assert_equal(359r, c.hue)

      c = Charty::Colors::HSL.new(361, 128, 255)
      assert_equal(1r, c.hue)

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, 0x100, 0)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, 0, 0x100)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, -1, 0)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, 0, -1)
      end
    end

    test("with float values") do
      c = Charty::Colors::HSL.new(0.0.next_float, 0.55, 1)
      assert_equal(0.0.next_float.to_r, c.hue)
      assert_equal(0.55.to_r, c.saturation)
      assert_equal(1.0.to_r, c.lightness)

      c = Charty::Colors::HSL.new(-0.1, 0.55, 1)
      assert_equal(360 - 0.1, c.hue)

      c = Charty::Colors::HSL.new(360.1, 0.55, 1)
      assert_equal(Rational(360.1) - 360, c.hue)

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0.0, 1.0.next_float, 0.0)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0.0, 0.0, 1.0.next_float)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, -0.1, 0)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0, 0, -0.1)
      end
    end

    test("with rational values") do
      c = Charty::Colors::HSL.new(1r, 500/1000r, 1)
      assert_equal(1r, c.hue)
      assert_equal(500/1000r, c.saturation)
      assert_equal(1r, c.lightness)

      c = Charty::Colors::HSL.new(-1r, 500/1000r, 1)
      assert_equal(359r, c.hue)

      c = Charty::Colors::HSL.new(361r, 500/1000r, 1)
      assert_equal(1r, c.hue)

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0r, 1001/1000r, 0r)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0r, 0r, 1001/1000r)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0r, -1/1000r, 0r)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::HSL.new(0r, 0r, -1/1000r)
      end
    end
  end

  test("#hue=") do
    c = Charty::Colors::HSL.new(0, 0, 0)
    c.hue = 1r
    assert_equal(1r, c.hue)
    c.hue = 1.0r
    assert_equal(1r, c.hue)
    c.hue = 1
    assert_equal(1r, c.hue)
    c.hue = -1
    assert_equal(359r, c.hue)
    c.hue = 360
    assert_equal(0r, c.hue)
    c.hue = 361
    assert_equal(1r, c.hue)
  end

  test("#saturation=") do
    c = Charty::Colors::HSL.new(0, 0, 0)
    c.saturation = 1r
    assert_equal(1r, c.saturation)
    c.saturation = 1.0r
    assert_equal(1r, c.saturation)
    c.saturation = 1
    assert_equal(1/255r, c.saturation)
    assert_raise(ArgumentError) do
      c.saturation = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.saturation = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.saturation = -0.1
    end
    assert_raise(ArgumentError) do
      c.saturation = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.saturation = 256
    end
    assert_raise(ArgumentError) do
      c.saturation = -1
    end
  end

  test("#lightness=") do
    c = Charty::Colors::HSL.new(0, 0, 0)
    c.lightness = 1r
    assert_equal(1r, c.lightness)
    c.lightness = 1.0r
    assert_equal(1r, c.lightness)
    c.lightness = 1
    assert_equal(1/255r, c.lightness)
    assert_raise(ArgumentError) do
      c.lightness = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.lightness = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.lightness = -0.1
    end
    assert_raise(ArgumentError) do
      c.lightness = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.lightness = 256
    end
    assert_raise(ArgumentError) do
      c.lightness = -1
    end
  end

  test("==") do
    assert { Charty::Colors::HSL.new(0, 0, 0) == Charty::Colors::HSL.new(0, 0, 0) }
    assert { Charty::Colors::HSL.new(0, 0, 0) == Charty::Colors::HSLA.new(0, 0, 0, 1r) }
  end

  test("!=") do
    assert { Charty::Colors::HSL.new(0, 0, 0) != Charty::Colors::HSL.new(1, 0, 0) }
    assert { Charty::Colors::HSL.new(0, 0, 0) != Charty::Colors::HSL.new(0, 1, 0) }
    assert { Charty::Colors::HSL.new(0, 0, 0) != Charty::Colors::HSL.new(0, 0, 1) }
    assert { Charty::Colors::HSL.new(0, 0, 0) != Charty::Colors::HSLA.new(0, 0, 0, 0) }
  end

  test("to_hsl") do
    black = Charty::Colors::HSL.new(0, 0, 0)
    assert_same(black, black.to_hsl)
  end

  test("#to_hsla") do
    black = Charty::Colors::HSL.new(0, 0, 0)
    assert_equal(Charty::Colors::HSLA.new(0, 0, 0, 255),
                 black.to_hsla)
    assert_equal(Charty::Colors::HSLA.new(0, 0, 0, 0),
                 black.to_hsla(alpha: 0))
    assert_equal(Charty::Colors::HSLA.new(0, 0, 0, 0.5),
                 black.to_hsla(alpha: 0.5))

    assert_raise(ArgumentError) do
      black.to_hsla(alpha: nil)
    end

    assert_raise(ArgumentError) do
      black.to_hsla(alpha: 256)
    end

    assert_raise(ArgumentError) do
      black.to_hsla(alpha: -0.1)
    end

    assert_raise(ArgumentError) do
      black.to_hsla(alpha: 1.0.next_float)
    end
  end

  test("to_rgb") do
    # black
    assert_equal(Charty::Colors::RGB.new(0, 0, 0),
                 Charty::Colors::HSL.new(0, 0, 0).to_rgb)
    # red
    assert_equal(Charty::Colors::RGB.new(1r, 0r, 0r),
                 Charty::Colors::HSL.new(0r, 1r, 0.5r).to_rgb)
    # yellow
    assert_equal(Charty::Colors::RGB.new(1r, 1r, 0r),
                 Charty::Colors::HSL.new(60r, 1r, 0.5r).to_rgb)
    # green
    assert_equal(Charty::Colors::RGB.new(0r, 1r, 0r),
                 Charty::Colors::HSL.new(120r, 1r, 0.5r).to_rgb)
    # cyan
    assert_equal(Charty::Colors::RGB.new(0r, 1r, 1r),
                 Charty::Colors::HSL.new(180r, 1r, 0.5r).to_rgb)
    # blue
    assert_equal(Charty::Colors::RGB.new(0r, 0r, 1r),
                 Charty::Colors::HSL.new(240r, 1r, 0.5r).to_rgb)
    # magenta
    assert_equal(Charty::Colors::RGB.new(1r, 0r, 1r),
                 Charty::Colors::HSL.new(300r, 1r, 0.5r).to_rgb)
    # white
    assert_equal(Charty::Colors::RGB.new(1r, 1r, 1r),
                 Charty::Colors::HSL.new(0r, 1r, 1r).to_rgb)
  end

  test("to_rgba") do
    # black
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 1r),
                 Charty::Colors::HSL.new(0, 0, 0).to_rgba)
    # red
    assert_equal(Charty::Colors::RGBA.new(1r, 0r, 0r, 1r),
                 Charty::Colors::HSL.new(0r, 1r, 0.5r).to_rgba)
    # yellow
    assert_equal(Charty::Colors::RGBA.new(1r, 1r, 0r, 1r),
                 Charty::Colors::HSL.new(60r, 1r, 0.5r).to_rgba)
    # green
    assert_equal(Charty::Colors::RGBA.new(0r, 1r, 0r, 1r),
                 Charty::Colors::HSL.new(120r, 1r, 0.5r).to_rgba)
    # cyan
    assert_equal(Charty::Colors::RGBA.new(0r, 1r, 1r, 1r),
                 Charty::Colors::HSL.new(180r, 1r, 0.5r).to_rgba)
    # blue
    assert_equal(Charty::Colors::RGBA.new(0r, 0r, 1r, 1r),
                 Charty::Colors::HSL.new(240r, 1r, 0.5r).to_rgba)
    # magenta
    assert_equal(Charty::Colors::RGBA.new(1r, 0r, 1r, 1r),
                 Charty::Colors::HSL.new(300r, 1r, 0.5r).to_rgba)
    # white
    assert_equal(Charty::Colors::RGBA.new(1r, 1r, 1r, 1r),
                 Charty::Colors::HSL.new(0r, 1r, 1r).to_rgba)
  end
end
