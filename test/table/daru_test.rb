require "daru"

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
