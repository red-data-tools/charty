class TableDaruTest < Test::Unit::TestCase
  def setup
    @data = Daru::DataFrame.new(
      "Beer" => [
                  "Kingfisher",
                  "Snow",
                  "Bud Light",
                  "Tiger Beer",
                  "Budweiser",
                ],
      "Gallons sold" => [
                          500,
                          400,
                          450,
                          200,
                          250,
                        ]
    )
    @table = Charty::Table.new(@data)
  end

  sub_test_case("#index") do
    sub_test_case("without explicit index") do
      def test_index
        assert_equal({
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
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
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
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
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
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
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
                       length: 2,
                       values: ["Beer", "Gallons sold"],
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
        @table.columns = 3...5
        assert_equal({
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
                       length: 2,
                       values: [3, 4],
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
        @table.columns = ["a", "b"]
        assert_equal({
                       class: Charty::TableAdapters::DaruAdapter::IndexAdapter,
                       length: 2,
                       values: ["a", "b"],
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
    assert_equal(["Beer", "Gallons sold"],
                 @table.column_names)
  end

  sub_test_case("#[]") do
    test("row index and column name") do
      assert_equal("Bud Light",
                   @table[2, "Beer"])
      assert_equal(400,
                   @table[1, "Gallons sold"])
    end

    test("column name only") do
      assert_equal(Daru::Vector.new([
                     "Kingfisher",
                     "Snow",
                     "Bud Light",
                     "Tiger Beer",
                     "Budweiser",
                   ]),
                   @table["Beer"])
      assert_equal(Daru::Vector.new([
                     500,
                     400,
                     450,
                     200,
                     250,
                   ]),
                   @table["Gallons sold"])
    end
  end
end
