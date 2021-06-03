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

  def test_length
    assert_equal(5,
                 @table.length)
  end

  sub_test_case("#index") do
    sub_test_case("without explicit index") do
      def test_index
        assert_equal({
                       class: Charty::DaruIndex,
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
                       class: Charty::DaruIndex,
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
                       class: Charty::DaruIndex,
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
                       class: Charty::DaruIndex,
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
                       class: Charty::DaruIndex,
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
                       class: Charty::DaruIndex,
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
    sub_test_case("with default index") do
      test("class") do
        assert_equal(Charty::Vector,
                     @table["Beer"].class)
      end

      test("names") do
        assert_equal({
                       "Beer" => "Beer",
                       "Gallons sold" => "Gallons sold"
                     },
                     {
                       "Beer" => @table["Beer"].name,
                       "Gallons sold" => @table["Gallons sold"].name
                     })
      end

      test("values") do
        vectors = [
          Daru::Vector.new([
            "Kingfisher",
            "Snow",
            "Bud Light",
            "Tiger Beer",
            "Budweiser",
          ]),
          Daru::Vector.new([
            500,
            400,
            450,
            200,
            250,
          ]),
        ]
        assert_equal({
                       "Beer" => vectors[0],
                       "Gallons sold" => vectors[1]
                     },
                     {
                       "Beer" => @table["Beer"].data,
                       "Gallons sold" => @table["Gallons sold"].data
                     })
      end
    end

    sub_test_case("with non-default index") do
      def test_aref
        @table.index = [1, 20, 300, 4000, 50000]
        assert_equal([1, 20, 300, 4000, 50000],
                     @table["Beer"].index.to_a)
      end
    end
  end

  sub_test_case("#drop_na") do
    def test_equality
      omit("TODO: Support drop_na in daru table adapter")
    end
  end
end
