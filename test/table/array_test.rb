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
      sub_test_case("with default index") do
        test("class") do
          assert_equal({
                         X0: Charty::Vector,
                         X1: Charty::Vector,
                         X2: Charty::Vector,
                         X3: Charty::Vector,
                       },
                       {
                         X0: @table["X0"].class,
                         X1: @table["X1"].class,
                         X2: @table["X2"].class,
                         X3: @table["X3"].class
                       })
        end

        test("name") do
          assert_equal({
                         X0: :X0,
                         X1: :X1,
                         X2: :X2,
                         X3: :X3,
                       },
                       {
                         X0: @table["X0"].name,
                         X1: @table["X1"].name,
                         X2: @table["X2"].name,
                         X3: @table["X3"].name
                       })
        end

        test("values") do
          assert_equal({
                         X0: [1, 5],
                         X1: [2, 6],
                         X2: [3, 7],
                         X3: [4, 8]
                       },
                       {
                         X0: @table["X0"].data,
                         X1: @table["X1"].data,
                         X2: @table["X2"].data,
                         X3: @table["X3"].data
                       })
        end

        test("index") do
          assert_equal([0, 1],
                       @table["X0"].index.to_a)
        end
      end

      sub_test_case("with non-default index") do
        test("index") do
          @table.index = [100, 2000]
          assert_equal([100, 2000],
                       @table["X0"].index.to_a)
        end
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
      test("class") do
        assert_equal(Charty::Vector,
                     @table["X0"].class)
      end

      test("name") do
        assert_equal(:X0,
                     @table["X0"].name)
      end

      test("values") do
        assert_equal([1, 2, 3, 4, 5],
                     @table["X0"].data)
      end
    end
  end
end
