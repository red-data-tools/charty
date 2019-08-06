require 'test_helper'

class TableArrayTest < Test::Unit::TestCase
  sub_test_case("an array of arrays as records") do
    def setup
      @data = [
                [1, 2, 3, 4],
                [5, 6, 7, 8],
              ]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0", "X1", "X2", "X3"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        assert_equal(1,
                     @table[0, "X0"])
        assert_equal(7,
                     @table[1, "X2"])
      end

      test("column name only") do
        assert_equal([1, 5],
                     @table["X0"])
        assert_equal([2, 6],
                     @table["X1"])
        assert_equal([3, 7],
                     @table["X2"])
        assert_equal([4, 8],
                     @table["X3"])
      end
    end
  end

  sub_test_case("an array") do
    def setup
      @data = [1, 2, 3, 4, 5]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        assert_equal(1,
                     @table[0, "X0"])
        assert_equal(4,
                     @table[3, "X0"])
      end

      test("column name only") do
        assert_equal([1, 2, 3, 4, 5],
                     @table["X0"])
      end
    end
  end
end
