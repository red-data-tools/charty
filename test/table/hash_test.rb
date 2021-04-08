class TableHashTest < Test::Unit::TestCase
  def setup
    @data = {
      foo: [1, 2, 3, 4, 5],
      bar: [10, 20, 30, 40, 50],
      baz: [100, 200, 300, 400, 500],
    }
    @table = Charty::Table.new(@data)
  end

  test("new with explicit columns") do
    omit("TODO")
    table = Charty::Table.new(@data, columns: [:a, :b, :c])
    assert_equal([:a, :b, :c],
                 table.index.to_a)
  end

  sub_test_case("#index") do
    sub_test_case("without explicit index") do
      def test_index
        assert_equal({
                       class: Charty::RangeIndex,
                       length: 5,
                       values: [0, 1, 2, 3, 4],
                     },
                     {
                       class: @table.index.class,
                       length: @table.index.length,
                       values: @table.index.to_a
                     })
      end
    end

    sub_test_case("with explicit range index") do
      def test_index
        @table.index = 10...15
        assert_equal({
                       class: Charty::RangeIndex,
                       length: 5,
                       values: [10, 11, 12, 13, 14],
                     },
                     {
                       class: @table.index.class,
                       length: @table.index.length,
                       values: @table.index.to_a
                     })
      end
    end

    sub_test_case("with explicit string index") do
      def test_index
        @table.index = ["a", "b", "c", "d", "e"]
        assert_equal({
                       class: Charty::Index,
                       length: 5,
                       values: ["a", "b", "c", "d", "e"]
                     },
                     {
                       class: @table.index.class,
                       length: @table.index.length,
                       values: @table.index.to_a
                     })
      end
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

  sub_test_case("#columns") do
    sub_test_case("default columns") do
      def test_columns
        assert_equal({
                       class: Charty::Index,
                       length: 3,
                       values: [:foo, :bar, :baz],
                     },
                     {
                       class: @table.columns.class,
                       length: @table.columns.length,
                       values: @table.columns.to_a
                     })
      end
    end

    sub_test_case("with range columns") do
      def test_columns
        @table.columns = 3...6
        assert_equal({
                       class: Charty::RangeIndex,
                       length: 3,
                       values: [3, 4 ,5],
                     },
                     {
                       class: @table.columns.class,
                       length: @table.columns.length,
                       values: @table.columns.to_a
                     })
      end
    end

    sub_test_case("with string columns") do
      def test_columns
        @table.columns = ["a", "b", "c"]
        assert_equal({
                       class: Charty::Index,
                       length: 3,
                       values: ["a", "b", "c"],
                     },
                     {
                       class: @table.columns.class,
                       length: @table.columns.length,
                       values: @table.columns.to_a
                     })
      end
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

  test("#column_names") do
    assert_equal([:foo, :bar, :baz],
                 @table.column_names)
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
