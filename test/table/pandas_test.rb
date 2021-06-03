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

  def test_length
    assert_equal(2,
                 @table.length)
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

  sub_test_case("#drop_na") do
    def setup
      pandas_required
      @data = Pandas::DataFrame.new(data: {
        foo: [1, Float::NAN, 3, 4, 5],
        bar: [10, 20, 30, 40, 50],
        baz: ["a", "b", "c", nil, "e"]
      })
      @table = Charty::Table.new(@data)
    end

    def test_equality
      assert_equal(Charty::Table.new(
                     Pandas::DataFrame.new(
                       data: {
                         foo: [1.0, 3.0, 5.0],
                         bar: [10, 30, 50],
                         baz: ["a", "c", "e"]
                       },
                       index: [0, 2, 4]
                     )
                   ),
                   @table.drop_na)
    end
  end
end
