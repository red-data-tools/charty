class TableNMatrixTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    nmatrix_required
  end

  sub_test_case("an array of vectors as records") do
    def setup
      super
      @data = [
                NMatrix[1, 2, 3, 4],
                NMatrix[5, 6, 7, 8],
              ]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0", "X1", "X2", "X3"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      sub_test_case("with default index") do
        test("class") do
          assert_equal({
                         "X0" => Charty::Vector,
                         "X1" => Charty::Vector,
                         "X2" => Charty::Vector,
                         "X3" => Charty::Vector
                       },
                       {
                         "X0" => @table["X0"].class,
                         "X1" => @table["X1"].class,
                         "X2" => @table["X2"].class,
                         "X3" => @table["X3"].class
                       })
        end

        test("name") do
          assert_equal({
                         "X0" => :X0,
                         "X1" => :X1,
                         "X2" => :X2,
                         "X3" => :X3
                       },
                       {
                         "X0" => @table["X0"].name,
                         "X1" => @table["X1"].name,
                         "X2" => @table["X2"].name,
                         "X3" => @table["X3"].name
                       })
        end

        test("data") do
          assert_equal({
                         "X0" => [1, 5],
                         "X1" => [2, 6],
                         "X2" => [3, 7],
                         "X3" => [4, 8]
                       },
                       {
                         "X0" => @table["X0"].data,
                         "X1" => @table["X1"].data,
                         "X2" => @table["X2"].data,
                         "X3" => @table["X3"].data
                       })
        end
      end

      sub_test_case("with non-default index") do
        def test_aref
          omit("TODO: Improve nmatrix support")
        end
      end
    end
  end

  sub_test_case("a vector") do
    def setup
      super
      @data = NMatrix[1, 2, 3, 4, 5]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      sub_test_case("with string column name") do
        test("class") do
          assert_equal(Charty::Vector,
                       @table["X0"].class)
        end

        test("name") do
          assert_equal(:X0,
                       @table["X0"].name)
        end

        test("data") do
          assert_equal(NMatrix[1, 2, 3, 4, 5],
                       @table["X0"].data)
        end
      end

      sub_test_case("with symbol column name") do
        test("class") do
          assert_equal(Charty::Vector,
                       @table[:X0].class)
        end

        test("name") do
          assert_equal(:X0,
                       @table[:X0].name)
        end

        test("values") do
          assert_equal(NMatrix[1, 2, 3, 4, 5],
                       @table[:X0].data)
        end
      end
    end
  end

  sub_test_case("a matrix") do
    def setup
      super
      @data = NMatrix[
                       [1, 5,  9],
                       [2, 6, 10],
                       [3, 7, 11],
                       [4, 8, 12],
                     ]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0", "X1", "X2"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      sub_test_case("with string column name") do
        test("class") do
          assert_equal({
                         "X0" => NMatrix[1, 2, 3, 4],
                         "X1" => NMatrix[5, 6, 7, 8],
                         "X2" => NMatrix[9, 10, 11, 12]
                       },
                       {
                         "X0" => @table["X0"].data,
                         "X1" => @table["X1"].data,
                         "X2" => @table["X2"].data
                       })
        end

        test("name") do
          assert_equal({
                         "X0" => :X0,
                         "X1" => :X1,
                         "X2" => :X2
                       },
                       {
                         "X0" => @table["X0"].name,
                         "X1" => @table["X1"].name,
                         "X2" => @table["X2"].name
                       })
        end

        test("values") do
          assert_equal({
                         "X0" => NMatrix[1, 2, 3, 4],
                         "X1" => NMatrix[5, 6, 7, 8],
                         "X2" => NMatrix[9, 10, 11, 12]
                       },
                       {
                         "X0" => @table["X0"].data,
                         "X1" => @table["X1"].data,
                         "X2" => @table["X2"].data
                       })
        end
      end

      sub_test_case("with symbol column name") do
        test("class") do
          assert_equal({
                         X0: Charty::Vector,
                         X1: Charty::Vector,
                         X2: Charty::Vector
                       },
                       {
                         X0: @table[:X0].class,
                         X1: @table[:X1].class,
                         X2: @table[:X2].class
                       })
        end

        test("name") do
          assert_equal({
                         X0: :X0,
                         X1: :X1,
                         X2: :X2
                       },
                       {
                         X0: @table[:X0].name,
                         X1: @table[:X1].name,
                         X2: @table[:X2].name
                       })
        end

        test("values") do
          assert_equal({
                         X0: NMatrix[1, 2, 3, 4],
                         X1: NMatrix[5, 6, 7, 8],
                         X2: NMatrix[9, 10, 11, 12]
                       },
                       {
                         X0: @table[:X0].data,
                         X1: @table[:X1].data,
                         X2: @table[:X2].data
                       })
        end
      end
    end
  end

  test("a 3-adic tensor") do
    data = NMatrix[
                    [
                      [1, 2, 3],
                      [4, 5, 6]
                    ],
                    [
                      [7, 8, 9],
                      [10, 11, 12]
                    ],
                  ]
    assert_raise(ArgumentError) do
      Charty::Table.new(data)
    end
  end
end
