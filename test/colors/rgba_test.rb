require_relative '../test_helper'

class ColorsRGBATest < Test::Unit::TestCase
  sub_test_case(".new") do
    test("with integer values") do
      c = Charty::Colors::RGBA.new(1, 128, 0, 255)
      assert_equal(1/255r, c.red)
      assert_equal(128/255r, c.green)
      assert_equal(0/255r, c.blue)
      assert_equal(255/255r, c.alpha)

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0, 0, 0x100, 0x100)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0, 0, -1, -1)
      end
    end

    test("with float values") do
      c = Charty::Colors::RGBA.new(0.0.next_float, 0.55, 1, 0.9)
      assert_equal(0.0.next_float.to_r, c.red)
      assert_equal(0.55.to_r, c.green)
      assert_equal(1.0.to_r, c.blue)
      assert_equal(0.9.to_r, c.alpha)

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0.0, 0.0, 9.9, 1.0.next_float)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0, 0, 0, -1.0)
      end
    end

    test("with rational values") do
      c = Charty::Colors::RGBA.new(1/1000r, 500/1000r, 1, 999/1000r)
      assert_equal(1/1000r, c.red)
      assert_equal(500/1000r, c.green)
      assert_equal(1r, c.blue)
      assert_equal(999/1000r, c.alpha)

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0, 0, 0, 1001/1000r)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGBA.new(0, 0, 0, -1/1000r)
      end
    end
  end

  test("#red=") do
    c = Charty::Colors::RGBA.new(0, 0, 0, 0)
    c.red = 1r
    assert_equal(1r, c.red)
    c.red = 1.0r
    assert_equal(1r, c.red)
    c.red = 1
    assert_equal(1/255r, c.red)
    assert_raise(ArgumentError) do
      c.red = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.red = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.red = -0.1
    end
    assert_raise(ArgumentError) do
      c.red = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.red = 256
    end
    assert_raise(ArgumentError) do
      c.red = -1
    end
  end

  test("#green=") do
    c = Charty::Colors::RGBA.new(0, 0, 0, 0)
    c.green = 1r
    assert_equal(1r, c.green)
    c.green = 1.0r
    assert_equal(1r, c.green)
    c.green = 1
    assert_equal(1/255r, c.green)
    assert_raise(ArgumentError) do
      c.green = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.green = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.green = -0.1
    end
    assert_raise(ArgumentError) do
      c.green = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.green = 256
    end
    assert_raise(ArgumentError) do
      c.green = -1
    end
  end

  test("#blue=") do
    c = Charty::Colors::RGBA.new(0, 0, 0, 0)
    c.blue = 1r
    assert_equal(1r, c.blue)
    c.blue = 1.0r
    assert_equal(1r, c.blue)
    c.blue = 1
    assert_equal(1/255r, c.blue)
    assert_raise(ArgumentError) do
      c.blue = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.blue = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.blue = -0.1
    end
    assert_raise(ArgumentError) do
      c.blue = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.blue = 256
    end
    assert_raise(ArgumentError) do
      c.blue = -1
    end
  end

  test("#alpha=") do
    c = Charty::Colors::RGBA.new(0, 0, 0, 0)
    c.alpha = 1r
    assert_equal(1r, c.alpha)
    c.alpha = 1.0r
    assert_equal(1r, c.alpha)
    c.alpha = 1
    assert_equal(1/255r, c.alpha)
    assert_raise(ArgumentError) do
      c.alpha = 1001/1000r
    end
    assert_raise(ArgumentError) do
      c.alpha = -1/1000r
    end
    assert_raise(ArgumentError) do
      c.alpha = -0.1
    end
    assert_raise(ArgumentError) do
      c.alpha = 1.0.next_float
    end
    assert_raise(ArgumentError) do
      c.alpha = 256
    end
    assert_raise(ArgumentError) do
      c.alpha = -1
    end
  end

  test("#==") do
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) == Charty::Colors::RGBA.new(0, 0, 0, 0) }
    assert { Charty::Colors::RGBA.new(0, 0, 0, 1r) == Charty::Colors::RGB.new(0, 0, 0) }
  end

  test("!=") do
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) != Charty::Colors::RGBA.new(1, 0, 0, 0) }
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) != Charty::Colors::RGBA.new(0, 1, 0, 0) }
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) != Charty::Colors::RGBA.new(0, 0, 1, 0) }
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) != Charty::Colors::RGBA.new(0, 0, 0, 1) }
    assert { Charty::Colors::RGBA.new(0, 0, 0, 0) != Charty::Colors::RGB.new(0, 0, 0) }
  end

  test(".from_hex_string") do
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 0),
                 Charty::Colors::RGBA.from_hex_string("#0000"))
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 0),
                 Charty::Colors::RGBA.from_hex_string("#00000000"))
    assert_equal(Charty::Colors::RGBA.new(1, 0, 0, 0),
                 Charty::Colors::RGBA.from_hex_string("#01000000"))
    assert_equal(Charty::Colors::RGBA.new(0, 1, 0, 0),
                 Charty::Colors::RGBA.from_hex_string("#00010000"))
    assert_equal(Charty::Colors::RGBA.new(0, 0, 1, 0),
                 Charty::Colors::RGBA.from_hex_string("#00000100"))
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 1),
                 Charty::Colors::RGBA.from_hex_string("#00000001"))
    assert_equal(Charty::Colors::RGBA.new(0x33, 0x66, 0x99, 0xcc),
                 Charty::Colors::RGBA.from_hex_string("#369c"))
    assert_equal(Charty::Colors::RGBA.new(255, 255, 255, 255),
                 Charty::Colors::RGBA.from_hex_string("#ffff"))

    assert_equal(Charty::Colors::RGBA.new(0x33, 0x66, 0x99, 0xff),
                 Charty::Colors::RGBA.from_hex_string("#369"))
    assert_equal(Charty::Colors::RGBA.new(0x33, 0x66, 0x99, 0xff),
                 Charty::Colors::RGBA.from_hex_string("#336699"))

    assert_raise(ArgumentError) do
      Charty::Colors::RGBA.from_hex_string(nil)
    end

    assert_raise(ArgumentError) do
      Charty::Colors::RGBA.from_hex_string(1)
    end

    assert_raise(ArgumentError) do
      Charty::Colors::RGBA.from_hex_string("")
    end

    assert_raise(ArgumentError) do
      Charty::Colors::RGBA.from_hex_string("333")
    end

    assert_raise(ArgumentError) do
      Charty::Colors::RGBA.from_hex_string("#xxx")
    end
  end

  test("#to_hex_string") do
    assert_equal("#00000000",
                 Charty::Colors::RGBA.new(0, 0, 0, 0).to_hex_string)
    assert_equal("#ff000000",
                 Charty::Colors::RGBA.new(1r, 0, 0, 0).to_hex_string)
    assert_equal("#00ff0000",
                 Charty::Colors::RGBA.new(0, 1r, 0, 0).to_hex_string)
    assert_equal("#0000ff00",
                 Charty::Colors::RGBA.new(0, 0, 1r, 0).to_hex_string)
    assert_equal("#000000ff",
                 Charty::Colors::RGBA.new(0, 0, 0, 1r).to_hex_string)
    assert_equal("#ffffffff",
                 Charty::Colors::RGBA.new(1r, 1r, 1r, 1r).to_hex_string)
    assert_equal("#80808080",
                 Charty::Colors::RGBA.new(0.5, 0.5, 0.5, 0.5).to_hex_string)
    assert_equal("#33333333",
                 Charty::Colors::RGBA.new(0x33, 0x33, 0x33, 0x33).to_hex_string)
  end

  test("to_rgb") do
    black = Charty::Colors::RGBA.new(0, 0, 0, 1.0)
    assert_equal(Charty::Colors::RGB.new(0, 0, 0),
                 black.to_rgb)

    assert_raise(NotImplementedError) do
      Charty::Colors::RGBA.new(0, 0, 0, 0).to_rgb
    end
  end

  test("to_rgba") do
    black = Charty::Colors::RGBA.new(0, 0, 0, 1.0)
    assert_same(black, black.to_rgba)
  end

  test("#to_hsl") do
    # black
    assert_equal(Charty::Colors::HSL.new(0r, 0r, 0r),
                 Charty::Colors::RGB.new(0r, 0r, 0r).to_hsl)
    # red
    assert_equal(Charty::Colors::HSL.new(0r, 1r, 0.5r),
                 Charty::Colors::RGB.new(1r, 0r, 0r).to_hsl)
    # yellow
    assert_equal(Charty::Colors::HSL.new(60r, 1r, 0.5r),
                 Charty::Colors::RGB.new(1r, 1r, 0r).to_hsl)
    # green
    assert_equal(Charty::Colors::HSL.new(120r, 1r, 0.5r),
                 Charty::Colors::RGB.new(0r, 1r, 0r).to_hsl)
    # cyan
    assert_equal(Charty::Colors::HSL.new(180r, 1r, 0.5r),
                 Charty::Colors::RGB.new(0r, 1r, 1r).to_hsl)
    # blue
    assert_equal(Charty::Colors::HSL.new(240r, 1r, 0.5r),
                 Charty::Colors::RGB.new(0r, 0r, 1r).to_hsl)
    # magenta
    assert_equal(Charty::Colors::HSL.new(300r, 1r, 0.5r),
                 Charty::Colors::RGB.new(1r, 0r, 1r).to_hsl)
    # white
    assert_equal(Charty::Colors::HSL.new(0r, 0r, 1r),
                 Charty::Colors::RGB.new(1r, 1r, 1r).to_hsl)

    assert_raise(NotImplementedError) do
      Charty::Colors::RGBA.new(0, 0, 0, 0).to_hsl
    end
  end
end
