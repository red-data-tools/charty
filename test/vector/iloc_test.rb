class VectorIlocTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("Charty::Vector#iloc") do
    data(:adapter_type, [:array, :daru, :narray, :numpy, :pandas], keep: true)

    test("with the default index") do |data|
      vector = setup_vector(data[:adapter_type], [10, 20, 30])
      assert_equal([20, 10, 30],
                   [vector.iloc(1), vector.iloc(0), vector.iloc(2)])
    end

    test("with non-zero origin index") do |data|
      vector = setup_vector(data[:adapter_type], [10, 20, 30], index: [5, 10, 15])
      assert_equal([20, 10, 30],
                   [vector.iloc(1), vector.iloc(0), vector.iloc(2)])
    end

    test("with string index") do |data|
      vector = setup_vector(data[:adapter_type], [10, 20, 30], index: ["a", "b", "c"])
      assert_equal([20, 10, 30],
                   [vector.iloc(1), vector.iloc(0), vector.iloc(2)])
    end
  end

  def setup_vector(adapter_type, data, index: nil)
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
    Charty::Vector.new(Numo::Int64[*data], index: index)
  end

  def setup_vector_with_numpy(data, index)
    numpy_required
    Charty::Vector.new(Numpy.asarray(data, dtype: "int64"), index: index)
  end

  def setup_vector_with_pandas(data, index)
    pandas_required
    Charty::Vector.new(Pandas::Series.new(data), index: index)
  end
end
