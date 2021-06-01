class TableGroupByTest < Test::Unit::TestCase
  include Charty::TestHelpers

  data(:table_adapter, [:daru, :hash, :datasets, :pandas], keep: true)
  def test_class(data)
    setup_table(data[:table_adapter])
    expected_class = group_by_class(data[:table_adapter])
    assert_equal(expected_class,
                 @table.group_by(@grouper).class)
  end

  def test_indices(data)
    setup_table(data[:table_adapter])
    assert_equal(@expected_indices,
                 @table.group_by(@grouper).indices)
  end

  sub_test_case("group_keys") do
    def test_single_grouper(data)
      omit
      setup_table(data[:table_adapter])
      result = @table.group_by(@grouper).group_keys
      assert_equal([1, 2, 3, 4],
                   result)
    end

    def test_multiple_groupers(data)
      omit
      setup_table(data[:table_adapter])
      result = @table.group_by(@groupers).group_keys
      assert_equal([1, 2, 3, 4],
                   result)
    end
  end

  def test_apply(data)
    setup_table(data[:table_adapter])
    result = @table.group_by(@grouper).apply(*@apply_proc_args, &@apply_proc)
    assert_equal(@expected_applied_table,
                 result)
  end

  def setup_table(table_adapter)
    @data = {
      a: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      b: [1, 1, 1, 4, 4, 3, 2, 3, 3,  2,  4],
      c: %w[A B C D A B C D A B C]
    }

    @grouper = :b
    @groupers = [:b, :c]
    @expected_indices = {
      1 => [0, 1, 2],
      2 => [6, 9],
      3 => [5, 7, 8],
      4 => [3, 4, 10]
    }

    @apply_proc = ->(table, var) do
      {
        var => table[var].mean,
        "#{var}_min": table[var].min,
        "#{var}_max": table[var].max
      }
    end

    @apply_proc_args = [:a]

    @expected_applied_table = Charty::Table.new(
      {
        a: @expected_indices.values.map {|is| @data[:a].values_at(*is).mean },
        a_min: @expected_indices.values.map {|is| @data[:a].values_at(*is).min },
        a_max: @expected_indices.values.map {|is| @data[:a].values_at(*is).max }
      },
      index: Charty::Index.new(@expected_indices.keys, name: :b)
    )

    case table_adapter
    when :daru
      setup_table_by_daru
    when :hash
      setup_table_by_hash
    when :datasets
      setup_table_by_datasets
    when :pandas
      setup_table_by_pandas
    end
  end

  def setup_table_by_daru
    omit("TODO: Support group_by in daru table adapter")
  end

  def setup_table_by_hash
    @table = Charty::Table.new(@data)
  end

  def setup_table_by_datasets
    @data = Datasets::Penguins.new
    @table = Charty::Table.new(@data)
    @grouper = :species
    @groupers = [:species, :sex]
    @expected_indices = {
      "Adelie"    => (0...152).to_a,
      "Chinstrap" => (152...220).to_a,
      "Gentoo"    => (220...344).to_a
    }
    @apply_proc_args = [:year]
    @expected_applied_table = Charty::Table.new(
      {
        year:     @expected_indices.values.map {|is| @table[:year].values_at(*is).mean },
        year_min: @expected_indices.values.map {|is| @table[:year].values_at(*is).min },
        year_max: @expected_indices.values.map {|is| @table[:year].values_at(*is).max }
      },
      index: Charty::Index.new(@expected_indices.keys, name: :species)
    )
  end

  def setup_table_by_pandas
    @data = Pandas::DataFrame.new(data: @data)
    @table = Charty::Table.new(@data)
    df = Pandas::DataFrame.new(data: @expected_applied_table.adapter.data)
    df[:a_min] = df[:a_min].astype(:float64)
    df[:a_max] = df[:a_max].astype(:float64)
    @expected_applied_table = Charty::Table.new(df, index: @expected_applied_table.index)
  end

  def group_by_class(table_adapter)
    case table_adapter
    when :pandas
      Charty::TableAdapters::PandasDataFrameAdapter::GroupBy
    else
      Charty::Table::HashGroupBy
    end
  end
end
