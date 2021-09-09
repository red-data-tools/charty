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

  def test_indices_sorted(data)
    return if data[:table_adapter] == :datasets  # skip for red-datasets
    setup_table(data[:table_adapter])
    sorted_table = @table.sort_values(@sort_key)
    assert_equal(@expected_indices_after_sort,
                 sorted_table.group_by(@grouper).indices)
  end

  sub_test_case("group_keys") do
    data(:table_adapter, [:daru, :hash, :datasets, :pandas], keep: true)
    def test_single_grouper(data)
      setup_table(data[:table_adapter])
      result = @table.group_by(@grouper).group_keys
      assert_equal(@expected_indices.keys,
                   result)
    end

    def test_multiple_groupers(data)
      setup_table(data[:table_adapter])
      result = @table.group_by(@groupers).group_keys
      assert_equal(@expected_multiple_group_keys,
                   result)
    end
  end

  sub_test_case("each_group_key") do
    data(:table_adapter, [:daru, :hash, :datasets, :pandas], keep: true)
    def test_single_grouper(data)
      setup_table(data[:table_adapter])
      collected_keys = []
      @table.group_by(@grouper).each_group_key {|gk| collected_keys << gk }
      assert_equal(@expected_indices.keys,
                   collected_keys)
    end

    def test_multiple_groupers(data)
      setup_table(data[:table_adapter])
      collected_keys = []
      @table.group_by(@groupers).each_group_key {|gk| collected_keys << gk }
      assert_equal(@expected_multiple_group_keys,
                   collected_keys)
    end
  end

  def test_aref(data)
    setup_table(data[:table_adapter])
    groups = @table.group_by(@grouper)
    result = groups.each_group_key.map {|k| [k, groups[k]] }.to_h
    assert_equal(@expected_groups,
                 result)
  end

  def test_apply(data)
    setup_table(data[:table_adapter])
    result = @table.group_by(@grouper).apply(*@apply_proc_args, &@apply_proc)
    assert_equal(@expected_applied_table,
                 result)
  end

  def setup_table(table_adapter)
    @data = {
      a: [1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  4  ],
      b: [1,   1,   1,   4,   4,   3,   2,   3,   3,   2,   4,   2  ],
      c: ["A", "B", "C", "D", "A", "B", "C", "D", "A", "B", "C", "D"]
    }

    @grouper = :b
    @expected_indices = {
      1 => [0, 1, 2],
      2 => [6, 9, 11],
      3 => [5, 7, 8],
      4 => [3, 4, 10]
    }

    # @data_sorted = {
    #   a: [1,   2,   3,   4,   4,   5,   6,   7,   8,   9,   10,  11, ],
    #   b: [1,   1,   1,   4,   2,   4,   3,   2,   3,   3,   2,   4,  ],
    #   c: ["A", "B", "C", "D", "D", "A", "B", "C", "D", "A", "B", "C",]
    # }

    @sort_key = :a
    @expected_indices_after_sort = {
      1 => [0, 1, 2],
      2 => [4, 7, 10],
      3 => [6, 8, 9],
      4 => [3, 5, 11]
    }

    @groupers = [:b, :c]
    @expected_multiple_group_keys = [
      [1, "A"], [1, "B"], [1, "C"],
      [2, "B"], [2, "C"], [2, "D"],
      [3, "A"], [3, "B"], [3, "D"],
      [4, "A"], [4, "C"], [4, "D"]
    ]

    @expected_groups = @expected_indices.map {|key, index|
      [
        key,
        Charty::Table.new(
          {
            a: @data[:a].values_at(*index),
            b: @data[:b].values_at(*index),
            c: @data[:c].values_at(*index),
          },
          index: index
        )
      ]
    }.to_h

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
    @expected_indices = {
      "Adelie"    => (0...152).to_a,
      "Chinstrap" => (152...220).to_a,
      "Gentoo"    => (220...344).to_a
    }

    @groupers = [:species, :sex]
    @expected_multiple_group_keys = [
      ["Adelie", "female"],
      ["Adelie", "male"],
      ["Chinstrap", "female"],
      ["Chinstrap", "male"],
      ["Gentoo", "female"],
      ["Gentoo", "male"]
    ]

    @expected_groups = @expected_indices.map {|key, index|
      [
        key,
        Charty::Table.new(
          @table.column_names.map {|name|
            [
              name,
              @table[name].values_at(*index)
            ]
          }.to_h,
          index: Charty::Index.new(index, name: :species)
        )
      ]
    }.to_h

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
    pandas_required

    @data = Pandas::DataFrame.new(data: @data)
    @table = Charty::Table.new(@data)

    @expected_groups = @expected_indices.map {|key, index|
      [
        key,
        Charty::Table.new(
          Pandas::DataFrame.new(
            data: {
              a: @data[:a].iloc[index],
              b: @data[:b].iloc[index],
              c: @data[:c].iloc[index],
            },
            index: index
          )
        )
      ]
    }.to_h

    data = {}
    @expected_applied_table.adapter.data.each do |key, value|
      data[key] = value.to_a
    end
    df = Pandas::DataFrame.new(data: data)
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
