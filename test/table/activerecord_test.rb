require 'test_helper'
require 'active_record'
require 'tmpdir'

class TableActiveRecordTest < Test::Unit::TestCase
  class TestRecord < ActiveRecord::Base
  end

  class TestRecordMigration < ActiveRecord::Migration[5.2]
    self.verbose = false

    def change
      create_table :test_records, id: false do |t|
        t.bigint :id, null: false
        t.string :name
        t.float  :rate
      end
    end
  end

  def setup
    TestRecord.establish_connection(adapter: "sqlite3", database: ":memory:")
    TestRecordMigration.new.exec_migration(TestRecord.connection, :up)
    TestRecord.create(id: 1, name: "foo",  rate: 0.1)
    TestRecord.create(id: 2, name: "bar",  rate: 0.2)
    TestRecord.create(id: 3, name: "baz",  rate: 0.3)
    TestRecord.create(id: 4, name: "qux",  rate: 0.4)
    TestRecord.create(id: 5, name: "quux", rate: 0.5)

    @data = TestRecord.all.map(&:attributes)
    @table = Charty::Table.new(TestRecord.all)
  end

  test("#columns") do
    assert_equal(["id", "name", "rate"],
                 @table.columns)
  end

  sub_test_case("#[]") do
    test("row index and column name") do
      assert_equal("baz",
                   @table[2, "name"])
      assert_equal(0.4,
                   @table[3, "rate"])
    end

    test("column name only") do
      assert_equal([1, 2, 3, 4, 5],
                   @table["id"])
      assert_equal(["foo", "bar", "baz", "qux", "quux"],
                   @table["name"])
      assert_equal([0.1, 0.2, 0.3, 0.4, 0.5],
                   @table["rate"])
    end
  end
end
