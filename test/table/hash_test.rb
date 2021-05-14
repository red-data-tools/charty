class TableHashTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    @data = {
      foo: [1, 2, 3, 4, 5],
      bar: [10, 20, 30, 40, 50],
      baz: [100, 200, 300, 400, 500],
    }
    @table = Charty::Table.new(@data)
  end

  sub_test_case(".new") do
    sub_test_case("with an array of Charty::Vector") do
      data(:vector_type, [:array, :daru_vector, :narray, :nmatrix, :numpy, :pandas_series])
      def test_new(data)
        data = setup_data(data[:vector_type])
        table = Charty::Table.new(data)
        assert_equal(@table, table)
      end

      def setup_data(vector_type)
        send("setup_#{vector_type}")
      end

      def setup_array
        data = @data.map { |key, val|
          [key, Charty::Vector.new(val)]
        }.to_h
      end

      def setup_daru_vector
        @data = @data.map { |key, val|
          [key, Daru::Vector.new(val)]
        }.to_h
        @table = Charty::Table.new(@data)
        setup_array
      end

      def setup_narray
        numo_required
        @data = @data.map { |key, val|
          [key, Numo::DFloat[*val]]
        }.to_h
        @table = Charty::Table.new(@data)
        setup_array
      end

      def setup_nmatrix
        nmatrix_required
        @data = @data.map { |key, val|
          [key, NMatrix.new([val.length], val, dtype: :float64)]
        }.to_h
        @table = Charty::Table.new(@data)
        setup_array
      end

      def setup_numpy
        numpy_required
        @data = @data.map { |key, val|
          [key, Numpy.asarray(val, dtype: :float64)]
        }.to_h
        @table = Charty::Table.new(@data)
        setup_array
      end

      def setup_pandas_series
        pandas_required
        @data = @data.map { |key, val|
          [key, Pandas::Series.new(val, dtype: :float64)]
        }.to_h
        @table = Charty::Table.new(@data)
        setup_array
      end
    end
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
    test("new with explicit columns") do
      table = Charty::Table.new(@data, columns: [:a, :b, :c])
      assert_equal([:a, :b, :c],
                   table.columns.to_a)
    end

    sub_test_case("default columns") do
      def test_columns
        assert_equal({
                       class: Charty::Index,
                       length: 3,
                       values: [:foo, :bar, :baz],
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
    assert_equal([:foo, :bar, :baz],
                 @table.column_names)
  end

  sub_test_case("#length") do
    data(
      "normal case"            => { input: {a: [1, 2, 3], b: [4, 5, 6]}, expected: 3 },
      "empty hash"             => { input: {}                          , expected: 0 },
      "hash with empty arrays" => { input: {a: [], b: []}              , expected: 0 }
    )
    def test_length(data)
      table = Charty::Table.new(data[:input])
      assert_equal(data[:expected],
                   table.length)
    end
  end

  sub_test_case("#[]") do
    test("with default index") do
      assert_equal(Charty::Vector,
                   @table[:foo].class)
      assert_equal([1, 2, 3, 4, 5],
                   @table[:foo].to_a)
      assert_equal([10, 20, 30, 40, 50],
                   @table[:bar].to_a)
      assert_equal([100, 200, 300, 400, 500],
                   @table[:baz].to_a)
    end

    test("with non-default index") do
      @table.index = [100, 2000, 30, 4, -5]
      assert_equal([100, 2000, 30, 4, -5],
                   @table[:foo].index.to_a)
    end
  end
end
