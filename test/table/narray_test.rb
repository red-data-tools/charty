class TableNArrayTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    numo_required
  end

  sub_test_case("an array of vectors as records") do
    def setup
      super
      @data = [
                Numo::DFloat[1, 2, 3, 4],
                Numo::DFloat[5, 6, 7, 8],
              ]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0", "X1", "X2", "X3"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      test("row index and column name") do
        assert_equal({
                       [0, "X0"] => 1,
                       [1, "X2"] => 7
                     },
                     {
                       [0, "X0"] => @table[0, "X0"],
                       [1, "X2"] => @table[1, "X2"]
                     })
      end

      test("column name only") do
        assert_equal({
                       :class => Charty::Vector,
                       "X0"   => [1, 5],
                       "X1"   => [2, 6],
                       "X2"   => [3, 7],
                       "X3"   => [4, 8]
                     },
                     {
                       :class => @table["X0"].class,
                       "X0"   => @table["X0"].data,
                       "X1"   => @table["X1"].data,
                       "X2"   => @table["X2"].data,
                       "X3"   => @table["X3"].data
                     })
      end
    end
  end

  sub_test_case("a vector") do
    def setup
      super
      @data = Numo::DFloat[1, 2, 3, 4, 5]
      @table = Charty::Table.new(@data)
    end

    test("#column_names") do
      assert_equal(["X0"],
                   @table.column_names)
    end

    sub_test_case("#[]") do
      sub_test_case("with string column name") do
        test("row index and column name") do
          assert_equal(1,
                       @table[0, "X0"])
          assert_equal(4,
                       @table[3, "X0"])
        end

        test("column name only") do
          assert_equal(Charty::Vector,
                       @table["X0"].class)
          assert_equal(Numo::DFloat[1, 2, 3, 4, 5],
                       @table["X0"])
        end
      end

      sub_test_case("with symbol column name") do
        test("row index and column name") do
          assert_equal(1,
                       @table[0, :X0])
          assert_equal(4,
                       @table[3, :X0])
        end

        test("column name only") do
          assert_equal(Numo::DFloat[1, 2, 3, 4, 5],
                       @table[:X0])
        end
      end
    end
  end

  sub_test_case("a matrix") do
    def setup
      super
      @data = Numo::DFloat[
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

    sub_test_case("with string column name") do
      sub_test_case("#[]") do
        test("row index and column name") do
          assert_equal({
                         [1, "X0"] => 2,
                         [2, "X2"] => 11,
                       },
                       {
                         [1, "X0"] => @table[1, "X0"],
                         [2, "X2"] => @table[2, "X2"]
                       })
        end

        test("column name only") do
          assert_equal({
                         :class => Charty::Vector,
                         "X0"   => Numo::DFloat[1, 2, 3, 4],
                         "X1"   => Numo::DFloat[5, 6, 7, 8],
                         "X2"   => Numo::DFloat[9, 10, 11, 12]
                       },
                       {
                         :class => @table["X0"].class,
                         "X0"   => @table["X0"].data,
                         "X1"   => @table["X1"].data,
                         "X2"   => @table["X2"].data
                       })
        end
      end
    end

    sub_test_case("with symbol column name") do
      sub_test_case("#[]") do
        test("row index and column name") do
          assert_equal({
                         [1, :X0] => 2,
                         [2, :X2] => 11,
                       },
                       {
                         [1, :X0] => @table[1, :X0],
                         [2, :X2] => @table[2, :X2]
                       })
        end

        test("column name only") do
          assert_equal({
                         :class => Charty::Vector,
                         :X0    => Numo::DFloat[1, 2, 3, 4],
                         :X1    => Numo::DFloat[5, 6, 7, 8],
                         :X2    => Numo::DFloat[9, 10, 11, 12]
                       },
                       {
                         :class => @table[:X0].class,
                         :X0    => @table[:X0].data,
                         :X1    => @table[:X1].data,
                         :X2    => @table[:X2].data
                       })
          assert_equal(Numo::DFloat[1, 2, 3, 4],
                       @table[:X0])
          assert_equal(Numo::DFloat[5, 6, 7, 8],
                       @table[:X1])
          assert_equal(Numo::DFloat[9, 10, 11, 12],
                       @table[:X2])
        end
      end
    end
  end

  test("a 3-adic tensor") do
    data = Numo::DFloat[
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
