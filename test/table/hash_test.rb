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

  test("#[]") do
    assert_equal(20,
                 @table[1, :bar])
  end
end
