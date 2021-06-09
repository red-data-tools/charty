class VectorValuesAtTest < Test::Unit::TestCase
  include Charty::TestHelpers

  data(:adapter_type, [:array, :daru, :narray, :nmatrix, :numpy, :pandas], keep: true)
  def test_values_at(data)
    vector = setup_vector(data[:adapter_type], [1, 2, 3, 4, 5], index: [1, 3, 5, 2, 4])
    assert_equal([1, 2, 3, 5, 4, 3],
                 vector.values_at(0, 1, 2, 4, 3, 2))
  end

  def setup_vector(adapter_type, data, index:)
    send("setup_vector_with_#{adapter_type}", data, index)
  end

  def setup_vector_with_array(data, index)
    Charty::Vector.new(data, index: index)
  end

  def setup_vector_with_daru(data, index)
    Charty::Vector.new(Daru::Vector.new(data), index: index)
  end

  def setup_vector_with_narray(data, index)
    numo_required
    Charty::Vector.new(Numo::Int32[*data], index: index)
  end

  def setup_vector_with_nmatrix(data, index)
    nmatrix_required
    Charty::Vector.new(NMatrix.new([data.length], data, dtype: :int32), index: index)
  end

  def setup_vector_with_numpy(data, index)
    numpy_required
    Charty::Vector.new(Numpy.array(data, dtype: :int32), index: index)
  end

  def setup_vector_with_pandas(data, index)
    pandas_required
    Charty::Vector.new(Pandas::Series.new(data, dtype: :int32), index: index)
  end
end
