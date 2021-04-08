class TablePandasTest < Test::Unit::TestCase
  def setup
    begin
      require "pandas"
    rescue LoadError
      omit("pandas is unavailable")
    end

    @data = Pandas::DataFrame.new(data: [[1, 2, 3], [4, 5, 6]], columns: ["a", "b", "c"])
    @table = Charty::Table.new(@data)
  end

  test("#column_names") do
    assert_equal(["a", "b", "c"],
                 @table.column_names)
  end

  sub_test_case("#[]") do
    test("when row and column are given") do
      assert_equal([
                     1,
                     5
                   ],
                   [
                     @table[0, "a"],
                     @table[1, "b"]
                   ])
    end

    test("when only column are given") do
      value = @table["b"]
      assert_equal({
                     class: Charty::Vector,
                     length: 2,
                     values: [2, 5]
                   },
                   {
                     class: value.class,
                     length: value.length,
                     values: value.to_a
                   })
    end
  end
end
