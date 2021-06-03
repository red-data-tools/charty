class UtilTest < Test::Unit::TestCase
  sub_test_case(".filter_map") do
    test("for array") do
      assert_equal([20, 40, 60, 80],
                   Charty::Util.filter_map([1, 2, 3, 4, 5, 6, 7, 8, 9]) {|x| x*10 if x.even? })
    end

    test("for range") do
      assert_equal([20, 40, 60, 80],
                   Charty::Util.filter_map(1..9) {|x| x*10 if x.even? })
    end
  end

  def test_missing_p
    pseudo_nil = Object.new
    class << pseudo_nil
      def nil?
        true
      end
    end

    assert_equal([
                   false,
                   false,
                   true,
                   false,
                   true,
                   false,
                   false,
                   true,
                   true
                 ],
                 [
                   Charty::Util.missing?(1),
                   Charty::Util.missing?(1.1),
                   Charty::Util.missing?(Float::NAN),
                   Charty::Util.missing?(Float::INFINITY),
                   Charty::Util.missing?(BigDecimal::NAN),
                   Charty::Util.missing?("nan"),
                   Charty::Util.missing?(Object.new),
                   Charty::Util.missing?(nil),
                   Charty::Util.missing?(pseudo_nil),
                 ])
  end

  def test_nan_p
    assert_equal([
                   false,
                   false,
                   true,
                   false,
                   true,
                   false,
                   false
                 ],
                 [
                   Charty::Util.nan?(1),
                   Charty::Util.nan?(1.1),
                   Charty::Util.nan?(Float::NAN),
                   Charty::Util.nan?(Float::INFINITY),
                   Charty::Util.nan?(BigDecimal::NAN),
                   Charty::Util.nan?("nan"),
                   Charty::Util.nan?(Object.new)
                 ])
  end
end
