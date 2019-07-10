require 'test_helper'
require 'numo/narray'

class TableNMatrixTest < Test::Unit::TestCase
  sub_test_case("an array of vectors as records") do
    def setup
      @data = [
                NMatrix[1, 2, 3, 4],
                NMatrix[5, 6, 7, 8],
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

  sub_test_case("a vector") do
    def setup
      @data = NMatrix[1, 2, 3, 4, 5]
      @table = Charty::Table.new(@data)
    end

    test("#columns") do
      assert_equal(["X0"],
                   @table.columns)
    end

    test("#[]") do
      assert_equal(1,
                   @table[0, "X0"])
      assert_equal(4,
                   @table[3, "X0"])
    end
  end

  sub_test_case("a matrix") do
    def setup
      @data = NMatrix[
                       [1, 5,  9],
                       [2, 6, 10],
                       [3, 7, 11],
                       [4, 8, 12],
                     ]
      @table = Charty::Table.new(@data)
    end

    test("#columns") do
      assert_equal(["X0", "X1", "X2"],
                   @table.columns)
    end

    test("#[]") do
      assert_equal(2,
                   @table[1, "X0"])
      assert_equal(11,
                   @table[2, "X2"])
    end
  end

  test("a 3-adic tensor") do
    data = NMatrix[
                    [
                      [1, 2, 3],
                      [4, 5, 6]
                    ],
                    [
                      [7, 8, 9],
                      [10, 11, 12]
                    ],
                  ]
    assert_raise(ArgumentError) do
      Charty::Table.new(data)
    end
  end
end
