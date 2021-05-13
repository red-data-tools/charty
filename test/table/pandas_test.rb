class TablePandasTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    pandas_required

    @data = Pandas::DataFrame.new(data: [[1, 2, 3], [4, 5, 6]], columns: ["a", "b", "c"])
    @table = Charty::Table.new(@data)
  end

  test("#column_names") do
    assert_equal(["a", "b", "c"],
                 @table.column_names)
  end

  sub_test_case("#columns") do
    def test_columns
      assert_equal(["a", "b", "c"],
                   @table.columns.to_a)
    end

    sub_test_case(".name") do
      def test_columns_name
        values = [@table.columns.name]
        @table.columns.name = "abc"
        values << @table.columns.name
        assert_equal([nil, "abc"], values)
      end
    end
  end

  sub_test_case("#index") do
    def test_index
      assert_equal([0, 1],
                   @table.index.to_a)
    end

    sub_test_case(".name") do
      def test_index_name
        values = [@table.index.name]
        @table.index.name = "abc"
        values << @table.index.name
        assert_equal([nil, "abc"], values)
      end
    end
  end

  sub_test_case("#[]") do
    test("with default index") do
      value = @table["b"]
      assert_equal({
                     class: Charty::Vector,
                     length: 2,
                     name: "b",
                     values: [2, 5]
                   },
                   {
                     class: value.class,
                     length: value.length,
                     name: value.name,
                     values: value.to_a
                   })
    end

    sub_test_case("with non-default index") do
      def test_aref
        @table.index = [1, 20]
        assert_equal([1, 20],
                     @table["b"].index.to_a)
      end
    end
  end
end
