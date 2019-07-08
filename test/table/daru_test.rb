require 'test_helper'
require 'daru'

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

  test("#columns") do
    assert_equal(["Beer", "Gallons sold"],
                 @table.columns)
  end

  test("#[]") do
    assert_equal("Bud Light",
                 @table[2, "Beer"])
    assert_equal(400,
                 @table[1, "Gallons sold"])
  end
end
