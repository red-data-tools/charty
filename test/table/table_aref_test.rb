class TableArefTest < Test::Unit::TestCase
  include Charty::TestHelpers

  data(:adapter_type, [:array_hash, :daru, :pandas], keep: true)
  data(:key_type,     [:string, :symbol], keep: true)
  def test_aref_by_string(data)
    table = setup_table(data[:adapter_type], data[:key_type])
    assert_equal({
                   "a" => Charty::Vector.new([1, 2, 3, 4, 5]),
                   "b" => Charty::Vector.new(["x", "y", "z", "z", "y"])
                 },
                 {
                   "a" => table["a"],
                   "b" => table["b"]
                 })
  end

  def test_aref_by_symbol(data)
    table = setup_table(data[:adapter_type], data[:key_type])
    assert_equal({
                   a: Charty::Vector.new([1, 2, 3, 4, 5]),
                   b: Charty::Vector.new(["x", "y", "z", "z", "y"])
                 },
                 {
                   a: table[:a],
                   b: table[:b]
                 })
  end

  sub_test_case("matrix data") do
    data(:adapter_type, [:narray, :nmatrix, :numpy], keep: true)
    data(:key_type,     [:string, :symbol], keep: true)
    def test_aref_by_string(data)
      table = setup_table(data[:adapter_type], data[:key_type])
      assert_equal({
                     "a" => Charty::Vector.new([1.0, 2.0, 3.0, 4.0, 5.0]),
                     "b" => Charty::Vector.new([10.0, 20.0, 30.0, 40.0, 50.0])
                   },
                   {
                     "a" => table["a"],
                     "b" => table["b"]
                   })
    end

    def test_aref_by_symbol(data)
      table = setup_table(data[:adapter_type], data[:key_type])
      assert_equal({
                     a: Charty::Vector.new([1.0, 2.0, 3.0, 4.0, 5.0]),
                     b: Charty::Vector.new([10.0, 20.0, 30.0, 40.0, 50.0])
                   },
                   {
                     a: table[:a],
                     b: table[:b]
                   })
    end

    def setup_table_by_narray(key_type)
      numo_required
      matrix = Numo::DFloat[[1, 2, 3, 4, 5], [10, 20, 30, 40, 50]].transpose
      Charty::Table.new(matrix, columns: setup_columns(key_type))
    end

    def setup_table_by_nmatrix(key_type)
      nmatrix_required
      omit("TODO: support nmatrix")
    end

    def setup_table_by_numpy(key_type)
      numpy_required
      omit("TODO: support numpy matrix")
      # matrix = Numpy.asarray([[1, 2, 3, 4, 5], [10, 20, 30, 40, 50]], dtype: :float64).T
      # Charty::Table.new(matrix, columns: setup_columns(key_type))
    end

    def setup_columns(key_type)
      columns = [:a, :b]
      if key_type == :string
        columns.map(&:to_s)
      else
        columns
      end
    end
  end

  def setup_table(adapter_type, key_type)
    send("setup_table_by_#{adapter_type}", key_type)
  end

  def setup_table_by_array_hash(key_type)
    Charty::Table.new(setup_raw_data(key_type))
  end

  def setup_table_by_daru(key_type)
    Charty::Table.new(Daru::DataFrame.new(setup_raw_data(key_type)))
  end

  def setup_table_by_pandas(key_type)
    pandas_required
    Charty::Table.new(Pandas::DataFrame.new(data: setup_raw_data(key_type)))
  end

  def setup_raw_data(key_type)
    data = {
      a: [1, 2, 3, 4, 5],
      b: ["x", "y", "z", "z", "y"]
    }
    if key_type == :string
      data.map { |k, v| [k.to_s, v] }.to_h
    else
      data
    end
  end
end
