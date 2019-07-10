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

    test("#columns") do
      assert_equal(["X0", "X1", "X2", "X3"],
                   @table.columns)
    end

    test("#[]") do
      assert_equal(1,
                   @table[0, "X0"])
      assert_equal(7,
                   @table[1, "X2"])
    end
  end
end
