class TableEqualityTest < Test::Unit::TestCase
  include Charty::TestHelpers

  data(:adapter_type,       [:array_hash, :daru, :narray_hash, :nmatrix_hash, :numpy_hash, :pandas], keep: true)
  data(:other_adapter_type, [:array_hash, :daru, :narray_hash, :nmatrix_hash, :numpy_hash, :pandas], keep: true)
  def test_equality(data)
    table = setup_table(data[:adapter_type])
    other_table = setup_table(data[:other_adapter_type])

    assert_equal(table, other_table)
  end

  def test_unequality_by_values(data)
    table = setup_table(data[:adapter_type])
    other_table = setup_table(data[:other_adapter_type], {
      "a" => [10, 20, 30, 40, 50],
      "b" => default_data["b"],
      "c" => default_data["c"],
      "d" => default_data["d"],
    })

    assert_not_equal(table, other_table)
  end

  def test_unequality_by_columns(data)
    table = setup_table(data[:adapter_type])
    other_table = setup_table(data[:other_adapter_type], columns: ["b", "c", "a", "d"])

    assert_not_equal(table, other_table)
  end

  def test_unequality_by_index(data)
    table = setup_table(data[:adapter_type])
    other_table = setup_table(data[:other_adapter_type], index: [10, 20, 30, 40, 50])

    assert_not_equal(table, other_table)
  end

  sub_test_case("with matrix") do
    data(:adapter_type,       [:array_hash, :daru, :narray_hash, :narray_matrix, :numpy_hash, :pandas], keep: true)
    data(:other_adapter_type, [:array_hash, :daru, :narray_hash, :narray_matrix, :numpy_hash, :pandas], keep: true)
    def test_equality(data)
      table = setup_table(data[:adapter_type])
      other_table = setup_table(data[:other_adapter_type])

      assert_equal(table, other_table)
    end

    def test_unequality_by_values(data)
      table = setup_table(data[:adapter_type])
      other_table = setup_table(data[:other_adapter_type], {
        "a" => [11, 21, 31, 41, 51],
        "b" => default_data["b"],
      })

      assert_not_equal(table, other_table)
    end

    def test_unequality_by_columns(data)
      table = setup_table(data[:adapter_type])
      other_table = setup_table(data[:other_adapter_type], columns: ["b", "c"])

      assert_not_equal(table, other_table)
    end

    def test_unequality_by_index(data)
      table = setup_table(data[:adapter_type])
      other_table = setup_table(data[:other_adapter_type], index: [10, 20, 30, 40, 50])

      assert_not_equal(table, other_table)
    end

    def setup_table_with_narray_matrix(data, dtypes, columns:, index:)
      numo_required
      data ||= default_data
      dtypes ||= default_dtypes
      columns ||= data.keys
      assert do
        dtypes.all? {|d| d == dtypes[0] }
      end

      data = data.values.transpose
      shape = [data.length, columns.length]
      data = numo_dtype(dtypes[0])[*data.flatten].reshape(*shape)
      Charty::Table.new(data, columns: columns, index: index)
    end

    def setup_table_with_nmatrix_matrix(data, dtypes, columns:, index:)
      nmatrix_required
      data ||= default_data
      dtypes ||= default_dtypes
      columns ||= data.keys
      assert do
        dtypes.all? {|d| d == dtypes[0] }
      end

      data = data.values.transpose
      shape = [data.length, columns.length]
      data = NMatrix.new(shape, data.flatten, dtype: dtypes[0])
    end

    def default_data
      {
        "a" => [1.0, 2.0, 3.0, 4.0, 5.0],
        "b" => [10.0, 20.0, 30.0, 40.0, 50.0]
      }
    end

    def default_dtypes
      [
        :float64,
        :float64,
      ]
    end
  end

  def setup_table(adapter_type, data=nil, dtypes=nil, columns: nil, index: nil)
    send("setup_table_with_#{adapter_type}", data, dtypes, columns: columns, index: index)
  end

  def setup_table_with_array_hash(data, _dtypes, columns:, index:)
    data ||= default_data
    Charty::Table.new(data, columns: columns, index: index)
  end

  def setup_table_with_daru(data, _dtypes, columns:, index:)
    data = Daru::DataFrame.new(data || default_data)
    Charty::Table.new(data, columns: columns, index: index)
  end

  def setup_table_with_narray_hash(data, dtypes, columns:, index:)
    numo_required
    data ||= default_data
    dtypes ||= default_dtypes
    data = data.map.with_index { |(k, v), i|
      [k, numo_dtype(dtypes[i])[*v]]
    }.to_h
    Charty::Table.new(data, columns: columns, index: index)
  end

  def setup_table_with_nmatrix_hash(data, dtypes, columns:, index:)
    nmatrix_required
    data ||= default_data
    dtypes ||= default_dtypes
    data = data.map.with_index { |(k, v), i|
      dtype = dtypes[i]
      dtype = :object if dtype == :bool
      [k, NMatrix.new([v.length], v, dtype: dtype)]
    }.to_h
    Charty::Table.new(data, columns: columns, index: index)
  end

  def setup_table_with_numpy_hash(data, dtypes, columns:, index:)
    numpy_required
    data ||= default_data
    dtypes ||= default_dtypes
    data = data.map.with_index { |(k, v), i|
      [k, Numpy.asarray(v, dtype: dtypes[i])]
    }.to_h
    Charty::Table.new(data, columns: columns, index: index)
  end

  def setup_table_with_pandas(data, dtypes, columns:, index:)
    pandas_required
    data ||= default_data
    dtypes ||= default_dtypes
    data = Pandas::DataFrame.new(data: data.map.with_index { |(k, v), i|
      [k, Pandas::Series.new(v, dtype: dtypes[i])]
    }.to_h)
    Charty::Table.new(data, columns: columns, index: index)
  end

  def default_data
    {
      "a" => [1, 2, 3, 4, 5],
      "b" => ["x", "y", "z", "z", "y"],
      "c" => [10.0, 20.0, 30.0, 40.0, 50.0],
      "d" => [true, false, true, false, true]
    }
  end

  def default_dtypes
    [
      :int64,
      :object,
      :float64,
      :bool
    ]
  end

  def numo_dtype(type)
    case type
    when :bool
      Numo::Bit
    when :int64
      Numo::Int64
    when :float64
      Numo::DFloat
    when :object
      Numo::RObject
    end
  end
end
