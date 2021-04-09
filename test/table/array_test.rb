class TableArrayTest < Test::Unit::TestCase
  sub_test_case("an array of arrays as records") do
    def setup
      @data = [
                [1, 2, 3, 4],
                [5, 6, 7, 8],
              ]
      @table = Charty::Table.new(@data)
    end

    def test_shape
      assert_equal([2, 4],
                   [@table.length, @table.column_length])
    end

    sub_test_case("#index") do
      sub_test_case("without explicit index") do
        def test_index
          assert_equal({
                         class: Charty::RangeIndex,
                         length: 2,
                         values: [0, 1],
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
          @table.index = 10...12
          assert_equal({
                         class: Charty::RangeIndex,
                         length: 2,
                         values: [10, 11],
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
          @table.index = ["a", "b"]
          assert_equal({
                         class: Charty::Index,
                         length: 2,
                         values: ["a", "b"]
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
                         length: 4,
                         values: ["X0", "X1", "X2", "X3"],
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
          @table.columns = 3...7
          assert_equal({
                         class: Charty::RangeIndex,
                         length: 4,
                         values: [3, 4, 5, 6],
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
          @table.columns = ["a", "b", "c", "d"]
          assert_equal({
                         class: Charty::Index,
                         length: 4,
                         values: ["a", "b", "c", "d"],
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
      assert_equal(["X0", "X1", "X2", "X3"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        assert_equal(1,
                     @table[0, "X0"])
        assert_equal(7,
                     @table[1, "X2"])
      end

      test("column name only") do
        assert_equal([1, 5],
                     @table["X0"])
        assert_equal([2, 6],
                     @table["X1"])
        assert_equal([3, 7],
                     @table["X2"])
        assert_equal([4, 8],
                     @table["X3"])
      end
    end
  end

  sub_test_case("an array") do
    def setup
      @data = [1, 2, 3, 4, 5]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0"],
                   @table.column_names)
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
                         length: 1,
                         values: ["X0"],
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
          @table.columns = 3...4
          assert_equal({
                         class: Charty::RangeIndex,
                         length: 1,
                         values: [3],
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
          @table.columns = ["a"]
          assert_equal({
                         class: Charty::Index,
                         length: 1,
                         values: ["a"],
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

    sub_test_case("#[]") do
      test("row index and column name") do
        assert_equal(1,
                     @table[0, "X0"])
        assert_equal(4,
                     @table[3, "X0"])
      end

      test("column name only") do
        assert_equal([1, 2, 3, 4, 5],
                     @table["X0"])
      end
    end
  end
end
