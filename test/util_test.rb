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
end
