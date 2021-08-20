class TableArrowTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    arrow_required
    @data = Arrow::Table.new(a: [1, 2, 3, 4],
                             b: [5, 6, 7, 8],
                             c: [9, 10, 11, 12])
    @table = Charty::Table.new(@data)
  end

  test("#column_names") do
    assert_equal(["a", "b", "c"],
                 @table.column_names)
  end

  sub_test_case("with string column name") do
    sub_test_case("#[]") do
      test("class") do
        assert_equal({
                       "a" => Charty::Vector,
                       "b" => Charty::Vector,
                       "c" => Charty::Vector,
                     },
                     {
                       "a" => @table["a"].class,
                       "b" => @table["b"].class,
                       "c" => @table["c"].class,
                     })
      end

      test("name") do
        assert_equal({
                       "a" => "a",
                       "b" => "b",
                       "c" => "c",
                     },
                     {
                       "a" => @table["a"].name,
                       "b" => @table["b"].name,
                       "c" => @table["c"].name,
                     })
      end

      test("values") do
        assert_equal({
                       "a" => Numo::DFloat[1, 2, 3, 4],
                       "b" => Numo::DFloat[5, 6, 7, 8],
                       "c" => Numo::DFloat[9, 10, 11, 12],
                     },
                     {
                       "a" => @table["a"].data,
                       "b" => @table["b"].data,
                       "c" => @table["c"].data,
                     })
      end
    end
  end

  sub_test_case("with symbol column name") do
    sub_test_case("#[]") do
      sub_test_case("with default index") do
        test("class") do
          assert_equal({
                         :a => Charty::Vector,
                         :b => Charty::Vector,
                         :c => Charty::Vector,
                       },
                       {
                         :a => @table[:a].class,
                         :b => @table[:b].class,
                         :c => @table[:c].class,
                       })
        end

        test("name") do
          assert_equal({
                         :a => "a",
                         :b => "b",
                         :c => "c",
                       },
                       {
                         :a => @table[:a].name,
                         :b => @table[:b].name,
                         :c => @table[:c].name,
                       })
        end

        test("values") do
          assert_equal({
                         :a => Arrow::Array.new([1, 2, 3, 4]),
                         :b => Arrow::Array.new([5, 6, 7, 8]),
                         :c => Arrow::Array.new([9, 10, 11, 12]),
                       },
                       {
                         :a => @table[:a].data,
                         :b => @table[:b].data,
                         :c => @table[:c].data,
                       })
        end
      end

      sub_test_case("with non-default index") do
        def test_aref
          @table.index = [1, 20, 300, 4000]
          assert_equal([1, 20, 300, 4000],
                       @table[:a].index.to_a)
        end
      end
    end
  end
end
