class TableResetIndexTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("with unnamed index") do
    data(:table_adapter, [:daru, :hash, :pandas], keep: true)
    def test_reset_index(data)
      setup_table(data[:table_adapter])
      assert_equal(@expected_result,
                   @table.reset_index)
    end

    def setup_table(table_adapter)
      @data = {
        a: [5, 4, 3, 2, 1],
      }
      @index = ["a", "b", "c", "d", "e"]

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
      omit("TODO: reset_index with daru")
    end

    def setup_table_by_hash
      @table = Charty::Table.new(@data, index: @index)
      @expected_result = Charty::Table.new(
        { index: @index }.merge(@data)
      )
    end

    def setup_table_by_pandas
      pandas_required

      @table = Charty::Table.new(Pandas::DataFrame.new(data: @data), index: @index)
      @expected_result = Charty::Table.new(
        Pandas::DataFrame.new(data: {index: @index}.merge(@data)))
    end
  end

  sub_test_case("with named index") do
    data(:table_adapter, [:daru, :hash, :pandas], keep: true)
    def test_reset_index(data)
      setup_table(data[:table_adapter])
      result = @table.group_by(@grouper).apply(:a) { |table, var|
        {
          var => table[var].mean,
          "#{var}_min": table[var].min,
          "#{var}_max": table[var].max
        }
      }.reset_index
      assert_equal(@expected_result,
                   result)
    end

    def setup_table(table_adapter)
      @data = {
        a: [1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11],
        b: [1,   1,   1,   4,   4,   3,   2,   3,   3,   2,   4],
        c: ["A", "B", "C", "D", "A", "B", "C", "D", "A", "B", "C"]
      }
      @grouper = :b
      @expected_indices = {
        1 => [0, 1, 2],
        2 => [6, 9],
        3 => [5, 7, 8],
        4 => [3, 4, 10]
      }
      @expected_applied_data = {
        a: @expected_indices.values.map {|is| @data[:a].values_at(*is).mean },
        a_min: @expected_indices.values.map {|is| @data[:a].values_at(*is).min },
        a_max: @expected_indices.values.map {|is| @data[:a].values_at(*is).max }
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
      omit("TODO: reset_index with daru")
    end

    def setup_table_by_hash
      @table = Charty::Table.new(@data)
      @expected_result = Charty::Table.new(
        { b: @expected_indices.keys }.merge(@expected_applied_data)
      )
    end

    def setup_table_by_pandas
      pandas_required

      @table = Charty::Table.new(Pandas::DataFrame.new(data: @data))

      df = Pandas::DataFrame.new(data: {b: @expected_indices.keys}.merge(@expected_applied_data))
      df[:a_min] = df[:a_min].astype(:float64)
      df[:a_max] = df[:a_max].astype(:float64)
      @expected_result = Charty::Table.new(df)
    end
  end
end

