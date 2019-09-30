require_relative './test_helper'

class ColorsTest < Test::Unit::TestCase
  test("Charty.RGB") do
    assert_equal(Charty::Colors::RGB.new(1, 2, 3),
                 Charty.RGB(1, 2, 3))
    assert_equal(Charty::Colors::RGB.new(0.1, 0.2, 0.3),
                 Charty.RGB(0.1, 0.2, 0.3))
    assert_equal(Charty::Colors::RGB.new(1, 2, 3),
                 Charty.RGB(Charty::Colors::RGBA.new(1, 2, 3, 255)))

    assert_raise(NotImplementedError) do
      Charty.RGB(Charty::Colors::RGBA.new(1, 2, 3, 4))
    end
  end

  test("Charty.RGBA") do
    assert_equal(Charty::Colors::RGBA.new(1, 2, 3, 4),
                 Charty.RGBA(1, 2, 3, 4))
    assert_equal(Charty::Colors::RGBA.new(0.1, 0.2, 0.3, 0.4),
                 Charty.RGBA(0.1, 0.2, 0.3, 0.4))
    assert_equal(Charty::Colors::RGBA.new(1, 2, 3, 255),
                 Charty.RGBA(Charty::Colors::RGB.new(1, 2, 3)))
    assert_equal(Charty::Colors::RGBA.new(1, 2, 3, 4),
                 Charty.RGBA(Charty::Colors::RGB.new(1, 2, 3), alpha: 4))

    assert_raise(ArgumentError) do
      Charty.RGBA(1, 2)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(1, 2)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(1, alpha: 1.0)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(Charty::Colors::RGB.new(0, 0, 0), beta: 0.0)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(Charty::Colors::RGB.new(0, 0, 0), alpha: 1.0, beta: 0.0)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(1, 2, 3)
    end

    assert_raise(ArgumentError) do
      Charty.RGBA(1, 2, 3, 4, 5)
    end
  end

  test("Charty.HSL") do
    assert_equal(Charty::Colors::HSL.new(1, 2, 3),
                 Charty.HSL(1, 2, 3))
    assert_equal(Charty::Colors::HSL.new(0.1, 0.2, 0.3),
                 Charty.HSL(0.1, 0.2, 0.3))
    assert_equal(Charty::Colors::HSL.new(60, 1r, 0.5r),
                 Charty.HSL(Charty::Colors::RGBA.new(1r, 1r, 0, 1r)))

    assert_raise(NotImplementedError) do
      Charty.HSL(Charty::Colors::RGBA.new(1, 2, 3, 4))
    end
  end
end
