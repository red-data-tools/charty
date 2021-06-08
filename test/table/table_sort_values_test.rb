class TableSortValuesTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("generic case") do
    data(:table_adapter, [:daru, :hash, :pandas], keep: true)
    def test_with_one_column(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_one_column,
                   @table.sort_values(:b))
    end

    def test_with_two_column(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_two_column,
                   @table.sort_values([:b, :c]))
    end

    sub_test_case("with red-datasets") do
      def test_sort_values
        omit("TODO: sort_values on datasets")
      end
    end

    def setup_table(table_adapter)
      @data = {
        a: Array.new(50) {|i| i },
        b: Array.new(50) {|i| 1 + rand(15) },
        c: Array.new(50) {|i| "ABCDE"[rand(5)] }
      }

      @order_one_column = (0 ... 50).sort_by {|i| [@data[:b][i], i] }
      @expected_one_column = @data.map { |k, v|
        [k, v.values_at(*@order_one_column)]
      }.to_h

      @order_two_column = (0 ... 50).sort_by {|i| [@data[:b][i], @data[:c][i], i] }
      @expected_two_column = @data.map { |k, v|
        [k, v.values_at(*@order_two_column)]
      }.to_h

      case table_adapter
      when :daru
        setup_table_by_daru
      when :hash
        setup_table_by_hash
      when :pandas
        setup_table_by_pandas
      end
    end

    def setup_table_by_daru
      omit("TODO: sort_values with daru")
    end

    def setup_table_by_hash
      @table = Charty::Table.new(@data)
      @expected_one_column = Charty::Table.new(@expected_one_column, index: @order_one_column)
      @expected_two_column = Charty::Table.new(@expected_two_column, index: @order_two_column)
    end

    def setup_table_by_pandas
      omit("TODO: sort_values with pandas")
    end
  end

  sub_test_case("including missing values") do
    data(:table_adapter, [:daru, :hash, :pandas], keep: true)
    def test_with_one_column_first(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_one_column_first,
                   @table.sort_values(:b, na_position: :first))
    end

    def test_with_one_column_last(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_one_column_last,
                   @table.sort_values(:b, na_position: :last))
    end

    def test_with_two_column_first(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_two_column_first,
                   @table.sort_values([:c, :b], na_position: :first))
    end

    def test_with_two_column_last(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_two_column_last,
                   @table.sort_values([:c, :b], na_position: :last))
    end

    sub_test_case("with red-datasets") do
      def test_sort_values
        omit("TODO: sort_values on datasets")
      end
    end

    def setup_table(table_adapter)
      nan = Float::NAN

      @data = {
        a: [1,   2,   3,   4,   5],
        b: [2.0, 4.0, nan, 1.0, 3.0],
        c: ["a", "b", "a", nil, "a"]
      }

      @order_one_column_first = [2, 3, 0, 4, 1]
      @expected_one_column_first = {
        a: [3,   4,    1,   5,   2],
        b: [nan, 1.0,  2.0, 3.0, 4.0],
        c: ["a", nil,  "a", "a", "b"]
      }

      @order_one_column_last = [3, 0, 4, 1, 2]
      @expected_one_column_last = {
        a: [4,    1,   5,   2,   3],
        b: [1.0,  2.0, 3.0, 4.0,   nan],
        c: [nil,  "a", "a", "b", "a"]
      }

      @order_two_column_first = [3, 2, 0, 4, 1]
      @expected_two_column_first = {
        a: [4,   3,   1,   5,   2],
        b: [1.0, nan, 2.0, 3.0, 4.0],
        c: [nil, "a", "a", "a", "b"]
      }

      @order_two_column_last = [0, 4, 2, 1, 3]
      @expected_two_column_last = {
        a: [1,   5,   3,   2,   4],
        b: [2.0, 3.0, nan, 4.0, 1.0],
        c: ["a", "a", "a", "b", nil]
      }

      case table_adapter
      when :daru
        setup_table_by_daru
      when :hash
        setup_table_by_hash
      when :pandas
        setup_table_by_pandas
      end
    end

    def setup_table_by_daru
      omit("TODO: sort_values with daru")
    end

    def setup_table_by_hash
      @table = Charty::Table.new(@data)
      @expected_one_column_first = Charty::Table.new(@expected_one_column_first, index: @order_one_column_first)
      @expected_one_column_last  = Charty::Table.new(@expected_one_column_last,  index: @order_one_column_last)
      @expected_two_column_first = Charty::Table.new(@expected_two_column_first, index: @order_two_column_first)
      @expected_two_column_last  = Charty::Table.new(@expected_two_column_last,  index: @order_two_column_last)
    end

    def setup_table_by_pandas
      @table = Charty::Table.new(Pandas::DataFrame.new(data: @data))
      @expected_one_column_first = Charty::Table.new(
        Pandas::DataFrame.new(data: @expected_one_column_first, index: @order_one_column_first))
      @expected_one_column_last  = Charty::Table.new(
        Pandas::DataFrame.new(data: @expected_one_column_last,  index: @order_one_column_last))
      @expected_two_column_first = Charty::Table.new(
        Pandas::DataFrame.new(data: @expected_two_column_first, index: @order_two_column_first))
      @expected_two_column_last  = Charty::Table.new(
        Pandas::DataFrame.new(data: @expected_two_column_last,  index: @order_two_column_last))
    end
  end
end
