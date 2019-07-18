require 'test_helper'

class TableHashTest < Test::Unit::TestCase
  def setup
    @data = {
      foo: [1, 2, 3, 4, 5],
      bar: [10, 20, 30, 40, 50],
      baz: [100, 200, 300, 400, 500],
    }
    @table = Charty::Table.new(@data)
  end

  test("#columns") do
    assert_equal([:foo, :bar, :baz],
                 @table.columns)
  end

  sub_test_case("#[]") do
    test("row index and column name") do
      assert_equal(20,
                   @table[1, :bar])
    end

    test("column name only") do
      assert_equal([1, 2, 3, 4, 5],
                   @table[:foo])
      assert_equal([10, 20, 30, 40, 50],
                   @table[:bar])
      assert_equal([100, 200, 300, 400, 500],
                   @table[:baz])
    end
  end
end
