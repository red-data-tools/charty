require "active_record"
require "tmpdir"

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
                       length: 3,
                       values: ["id", "name", "rate"],
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
        @table.columns = 3...6
        assert_equal({
                       class: Charty::RangeIndex,
                       length: 3,
                       values: [3, 4 ,5],
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
        @table.columns = ["a", "b", "c"]
        assert_equal({
                       class: Charty::Index,
                       length: 3,
                       values: ["a", "b", "c"],
                     },
                     {
                       class: @table.columns.class,
                       length: @table.columns.length,
                       values: @table.columns.to_a
                     })
      end
    end

    test("updating columns does not affect the original data") do
      @table.columns = 0 ... 3
      assert_equal(["id", "name", "rate"],
                   @table.adapter.data.column_names)
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
    assert_equal(["id", "name", "rate"],
                 @table.column_names)
  end

  sub_test_case("#[]") do
    sub_test_case("with string column name") do
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

    sub_test_case("with symbol column name") do
      test("row index and column name") do
        assert_equal("baz",
                     @table[2, :name])
        assert_equal(0.4,
                     @table[3, :rate])
      end

      test("column name only") do
        assert_equal([1, 2, 3, 4, 5],
                     @table[:id])
        assert_equal(["foo", "bar", "baz", "qux", "quux"],
                     @table[:name])
        assert_equal([0.1, 0.2, 0.3, 0.4, 0.5],
                     @table[:rate])
      end
    end
  end
end
