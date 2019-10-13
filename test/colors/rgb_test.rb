require_relative '../test_helper'

class ColorsRGBTest < Test::Unit::TestCase
  include TestHelper

  sub_test_case(".new") do
    test("with integer values") do
      c = Charty::Colors::RGB.new(1, 128, 255)
      assert_equal(1/255r, c.red)
      assert_equal(128/255r, c.green)
      assert_equal(255/255r, c.blue)

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0, 0, 0x100)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0, 0, -1)
      end
    end

    test("with float values") do
      c = Charty::Colors::RGB.new(0.0.next_float, 0.55, 1)
      assert_equal(0.0.next_float.to_r, c.red)
      assert_equal(0.55.to_r, c.green)
      assert_equal(1.0.to_r, c.blue)

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0.0, 0.0, 1.0.next_float)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0, 0, -0.1)
      end
    end

    test("with rational values") do
      c = Charty::Colors::RGB.new(1/1000r, 500/1000r, 1)
      assert_equal(1/1000r, c.red)
      assert_equal(500/1000r, c.green)
      assert_equal(1r, c.blue)

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0.0, 0.0, 1001/1000r)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.new(0, 0, -1/1000r)
      end
    end
  end

  test("#red=") do
    c = Charty::Colors::RGB.new(0, 0, 0)
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
    c = Charty::Colors::RGB.new(0, 0, 0)
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
    c = Charty::Colors::RGB.new(0, 0, 0)
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

  test("==") do
    assert { Charty::Colors::RGB.new(0, 0, 0) == Charty::Colors::RGB.new(0, 0, 0) }
    assert { Charty::Colors::RGB.new(0, 0, 0) == Charty::Colors::RGBA.new(0, 0, 0, 1r) }
  end

  test("!=") do
    assert { Charty::Colors::RGB.new(0, 0, 0) != Charty::Colors::RGB.new(1, 0, 0) }
    assert { Charty::Colors::RGB.new(0, 0, 0) != Charty::Colors::RGB.new(0, 1, 0) }
    assert { Charty::Colors::RGB.new(0, 0, 0) != Charty::Colors::RGB.new(0, 0, 1) }
    assert { Charty::Colors::RGB.new(0, 0, 0) != Charty::Colors::RGBA.new(0, 0, 0, 0) }
  end

  test("#desaturate") do
    c = Charty::Colors::RGB.new(1r, 1r, 1r).desaturate(0.8)
    assert_instance_of(Charty::Colors::RGB, c)
    assert_near(Charty::Colors::HSL.new(0r, 0.8r, 1r).to_rgb, c)
  end

  sub_test_case(".parse") do
    test("for #rgb") do
      assert_equal(Charty::Colors::RGB.new(0, 0, 0),
                   Charty::Colors::RGB.parse("#000"))
      assert_equal(Charty::Colors::RGB.new(0x33, 0x66, 0x99),
                   Charty::Colors::RGB.parse("#369"))
      assert_equal(Charty::Colors::RGB.new(255, 255, 255),
                   Charty::Colors::RGB.parse("#fff"))
    end

    test("for #rrggbb") do
      assert_equal(Charty::Colors::RGB.new(0, 0, 0),
                   Charty::Colors::RGB.parse("#000000"))
      assert_equal(Charty::Colors::RGB.new(1, 0, 0),
                   Charty::Colors::RGB.parse("#010000"))
      assert_equal(Charty::Colors::RGB.new(0, 1, 0),
                   Charty::Colors::RGB.parse("#000100"))
      assert_equal(Charty::Colors::RGB.new(0, 0, 1),
                   Charty::Colors::RGB.parse("#000001"))
    end


    test("error cases") do
      # `#rgba` is error
      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#0000")
      end

      # `#rrggbbaa` is error
      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#00000000")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#00")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#00000")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#0000000")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse(nil)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse(1)
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("333")
      end

      assert_raise(ArgumentError) do
        Charty::Colors::RGB.parse("#xxx")
      end
    end
  end

  test("#to_hex_string") do
    assert_equal("#000000",
                 Charty::Colors::RGB.new(0, 0, 0).to_hex_string)
    assert_equal("#ff0000",
                 Charty::Colors::RGB.new(1r, 0, 0).to_hex_string)
    assert_equal("#00ff00",
                 Charty::Colors::RGB.new(0, 1r, 0).to_hex_string)
    assert_equal("#0000ff",
                 Charty::Colors::RGB.new(0, 0, 1r).to_hex_string)
    assert_equal("#ffffff",
                 Charty::Colors::RGB.new(1r, 1r, 1r).to_hex_string)
    assert_equal("#808080",
                 Charty::Colors::RGB.new(0.5, 0.5, 0.5).to_hex_string)
    assert_equal("#333333",
                 Charty::Colors::RGB.new(0x33, 0x33, 0x33).to_hex_string)
  end

  test("to_rgb") do
    black = Charty::Colors::RGB.new(0, 0, 0)
    assert_same(black, black.to_rgb)
  end

  test("#to_rgba") do
    black = Charty::Colors::RGB.new(0, 0, 0)
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 255),
                 black.to_rgba)
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 0),
                 black.to_rgba(alpha: 0))
    assert_equal(Charty::Colors::RGBA.new(0, 0, 0, 0.5),
                 black.to_rgba(alpha: 0.5))

    assert_raise(ArgumentError) do
      black.to_rgba(alpha: nil)
    end

    assert_raise(ArgumentError) do
      black.to_rgba(alpha: 256)
    end

    assert_raise(ArgumentError) do
      black.to_rgba(alpha: -0.1)
    end

    assert_raise(ArgumentError) do
      black.to_rgba(alpha: 1.0.next_float)
    end
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
  end
end
