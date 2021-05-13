class VectorEqualityTest < Test::Unit::TestCase
  include Charty::TestHelpers

  data(:adapter_type,       [:array, :daru, :narray, :nmatrix, :numpy, :pandas], keep: true)
  data(:other_adapter_type, [:array, :daru, :narray, :nmatrix, :numpy, :pandas], keep: true)
  def test_equality(data)
    vector = setup_vector(data[:adapter_type])
    other_vector = setup_vector(data[:other_adapter_type])

    assert_equal(vector, other_vector)
  end

  def test_equality_with_different_names(data)
    vector = setup_vector(data[:adapter_type], name: "foo")
    other_vector = setup_vector(data[:other_adapter_type], name: "bar")

    assert_equal(vector, other_vector)
  end

  def test_unequality_by_values(data)
    vector = setup_vector(data[:adapter_type])
    other_vector = setup_vector(data[:other_adapter_type], [2, 3, 4, 5, 1])

    assert_not_equal(vector, other_vector)
  end

  def test_unequality_by_index(data)
    vector = setup_vector(data[:adapter_type])
    other_vector = setup_vector(data[:other_adapter_type], index: [10, 20, 30, 40, 50])

    assert_not_equal(vector, other_vector)
  end

  def setup_vector(adapter_type, data=nil, dtype=nil, index: nil, name: nil)
    send("setup_vector_with_#{adapter_type}", data, dtype, index: index, name: name)
  end

  def setup_vector_with_array(data, _dtype, index:, name:)
    data ||= default_data
    Charty::Vector.new(data, index: index, name: name)
  end

  def setup_vector_with_daru(data, _dtype, index:, name:)
    data ||= default_data
    data = Daru::Vector.new(data)
    Charty::Vector.new(data, index: index, name: name)
  end

  def setup_vector_with_narray(data, dtype, index:, name:)
    numo_required
    data ||= default_data
    dtype ||= default_dtype
    data = numo_dtype(dtype)[*data]
    Charty::Vector.new(data, index: index, name: name)
  end

  def setup_vector_with_nmatrix(data, dtype, index:, name:)
    nmatrix_required
    data ||= default_data
    dtype ||= default_dtype
    data = NMatrix.new([data.length], data, dtype: dtype)
    Charty::Vector.new(data, index: index, name: name)
  end

  def setup_vector_with_numpy(data, dtype, index:, name:)
    numpy_required
    data ||= default_data
    dtype ||= default_dtype
    data = Numpy.asarray(data, dtype: dtype)
    Charty::Vector.new(data, index: index, name: name)
  end

  def setup_vector_with_pandas(data, dtype, index:, name:)
    numpy_required
    data ||= default_data
    dtype ||= default_dtype
    data = Pandas::Series.new(data, dtype: dtype)
    Charty::Vector.new(data, index: index, name: name)
  end

  def default_data
    [1, 2, 3, 4, 5]
  end

  def default_dtype
    :int64
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
