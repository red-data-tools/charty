class VectorNumpyTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    pandas_required

    @data = Numpy.asarray([1, 2, 3, 4, 5], dtype: :float64)
    @vector = Charty::Vector.new(@data)
  end

  def test_length
    assert_equal(5, @vector.length)
  end

  def test_name
    values = [@vector.name]
    @vector.name = "abc"
    values << @vector.name
    assert_equal([nil, "abc"], values)
  end

  sub_test_case("#index") do
    sub_test_case("without explicit index") do
      def test_index
        assert_equal([0, 1, 2, 3, 4], @vector.index.to_a)
      end
    end

    sub_test_case("with string index") do
      def test_index
        @vector.index = ["a", "b", "c", "d", "e"]
        assert_equal(["a", "b", "c", "d", "e"], @vector.index.to_a)
      end
    end

    sub_test_case(".name") do
      def test_index_name
        values = [@vector.index.name]
        @vector.index.name = "abc"
        values << @vector.index.name
        assert_equal([nil, "abc"], values)
      end
    end
  end

  sub_test_case("#[]") do
    sub_test_case("without explicit index") do
      def test_aref
        assert_equal([
                       2,
                       4
                     ],
                     [
                       @vector[1],
                       @vector[3]
                     ])
      end
    end

    sub_test_case("with string index") do
      def test_aref
        @vector.index = ["a", "b", "c", "d", "e"]
        assert_equal([
                       2,
                       3,
                       4,
                       5
                     ],
                     [
                       @vector[1],
                       @vector["c"],
                       @vector["d"],
                       @vector[4]
                     ])
      end
    end

    sub_test_case("with boolean vector mask") do
      def setup_array_mask
        @mask_array = [false, true, false, true, false]
        @mask = Charty::Vector.new(@mask_array)
      end

      def setup_daru_mask
        setup_array_mask
        @mask = Charty::Vector.new(Daru::Vector.new(@mask_array))
      end

      def setup_narray_mask
        numo_required
        setup_array_mask
        @mask = Charty::Vector.new(Numo::Bit[*@mask_array])
      end

      def setup_narray_bool_obj_mask
        numo_required
        setup_array_mask
        @mask = Charty::Vector.new(Numo::RObject[*@mask_array])
      end

      def setup_numpy_mask
        pandas_required
        setup_array_mask
        @mask = Charty::Vector.new(Numpy.asarray(@mask_array, dtype: :bool))
      end

      def setup_numpy_bool_obj_mask
        pandas_required
        setup_array_mask
        @mask = Charty::Vector.new(Numpy.asarray(@mask_array, dtype: :object))
      end

      def setup_pandas_mask
        pandas_required
        setup_array_mask
        @mask = Charty::Vector.new(Pandas::Series.new(@mask_array, dtype: :bool))
      end

      def setup_pandas_bool_obj_mask
        pandas_required
        setup_array_mask
        @mask = Charty::Vector.new(Pandas::Series.new(@mask_array, dtype: :object))
      end

      data(:mask_adapter, [:array, :daru, :narray, :narray_bool_obj,
                           :numpy, :numpy_bool_obj, :pandas, :pandas_bool_obj])
      def test_aref_with_mask(data)
        mask_adapter = data[:mask_adapter]
        send("setup_#{mask_adapter}_mask")
        @vector.index = [10, 20, 30, 40, 50]
        @vector.name = "foo"
        result = @vector[@mask]
        assert_equal({
                       class: Charty::Vector,
                       data_class: Numpy::NDArray,
                       dtype: Numpy.float64,
                       values: [2.0, 4.0],
                       index: [20, 40],
                       name: "foo"
                     },
                     {
                       class: result.class,
                       data_class: result.data.class,
                       dtype: result.data.dtype,
                       values: result.data.to_a,
                       index: result.index.to_a,
                       name: "foo"
                     })
      end
    end
  end

  test("#to_a") do
    assert_equal([1, 2, 3, 4, 5],
                 @vector.to_a)
  end

  sub_test_case("#boolean?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]      , dtype: :float64  },
      "for string array"                   => { array: ["abc", "def", "xyz"], dtype: :str },
      "for numeric array with nan at head" => { array: [Float::NAN, 1, 2, 3], dtype: :float64  },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]  , dtype: :str }
    )
    def test_with_nonboolean_dtype_nonboolean(data)
      array, dtype = data.values_at(:array, :dtype)
      data = Numpy.asarray(array, dtype: dtype)
      vector = Charty::Vector.new(data)
      assert do
        not vector.boolean?
      end
    end

    data(
      "for boolean object array"                  => [true, false, true],
      "for boolean object array with nil at head" => [nil, true, false, true],
    )
    def test_with_nonboolean_dtype_boolean(data)
      data = Numpy.asarray(data, dtype: :object)
      vector = Charty::Vector.new(data)
      assert do
        vector.boolean?
      end
    end

    data(
      "for boolean array" => [true, false, true],
    )
    def test_with_boolean_dtype(data)
      data = Numpy.asarray(data, dtype: :bool)
      vector = Charty::Vector.new(data)
      assert do
        vector.boolean?
      end
    end
  end

  sub_test_case("#numeric?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , dtype: "float64", result: true },
      "for string array"                   => { array: ["abc", "def", "xyz"] , dtype: "str"    , result: false },
      "for numeric array with nil at head" => { array: [Float::NAN, 1, 2, 3] , dtype: "float64", result: true },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , dtype: "str"    , result: false },
    )
    def test_numeric(data)
      array, dtype, result = data.values_at(:array, :dtype, :result)
      data = Numpy.asarray(array, dtype: dtype)
      vector = Charty::Vector.new(data)
      assert_equal(result, vector.numeric?)
    end
  end

  sub_test_case("#categorical?") do
    data(
      "for numeric array"                  => [1, 2, 3, 4, 5],
      "for string array"                   => ["abc", "def", "xyz"],
      "for numeric array with nil at head" => [Float::NAN, 1, 2, 3],
      "for string array with nil at head"  => [nil, "abc", "xyz"]
    )
    def test_categorical_with_noncategorical(data)
      vector = Charty::Vector.new(Numpy.asarray(data))
      assert do
        not vector.categorical?
      end
    end
  end

  sub_test_case("#categories") do
    data(
      "for numeric array"                  => [1, 2, 3, 4, 5],
      "for string array"                   => ["abc", "def", "xyz"],
      "for numeric array with nil at head" => [nil, 1, 2, 3],
      "for string array with nil at head"  => [nil, "abc", "xyz"]
    )
    def test_categories_with_noncategorical(data)
      vector = Charty::Vector.new(Numpy.asarray(data))
      assert_nil(vector.categories)
    end
  end

  sub_test_case("#unique_values") do
    def setup
      super
      @data = Numpy.asarray([3, 1, 3, 2, 1])
      @vector = Charty::Vector.new(@data)
    end

    def test_unique_values
      result = @vector.unique_values
      assert_equal({
                     class: Array,
                     values: Numpy.unique(@data).to_a
                   },
                   {
                     class: result.class,
                     values: result
                   })
    end
  end

  sub_test_case("#group_by") do
    test("when grouper is also a Charty::Vector of a Pandas::Series") do
      vector = Charty::Vector.new(Numpy.asarray([1, 2, 3, 4, 5]))
      grouper = Charty::Vector.new(Numpy.asarray(["a", "b", "a", "a", "b"]))
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Numpy::NDArray, "b" => Numpy::NDArray },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is a Charty::Vector but not of a Pandas::Series") do
      vector = Charty::Vector.new(Numpy.asarray([1, 2, 3, 4, 5]))
      grouper = Charty::Vector.new(["a", "b", "a", "a", "b"])
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Numpy::NDArray, "b" => Numpy::NDArray },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is a Numpy::NDArray") do
      vector = Charty::Vector.new(Numpy.asarray([1, 2, 3, 4, 5]))
      grouper = Numpy.asarray(["a", "b", "a", "a", "b"])
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Numpy::NDArray, "b" => Numpy::NDArray },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is a Pandas::Series") do
      vector = Charty::Vector.new(Numpy.asarray([1, 2, 3, 4, 5]))
      grouper = Pandas::Series.new(["a", "b", "a", "a", "b"])
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Numpy::NDArray, "b" => Numpy::NDArray },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is an Array") do
      vector = Charty::Vector.new(Numpy.asarray([1, 2, 3, 4, 5]))
      grouper = ["a", "b", "a", "a", "b"]
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Numpy::NDArray, "b" => Numpy::NDArray },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end
  end

  data(
    "for numeric array without NA"  => { array: [1, 2, 3, 4, 5]                  , expected: [1, 2, 3, 4, 5] },
    "for string array without NA"   => { array: ["abc", "def", "xyz"]            , expected: ["abc", "def", "xyz"] },
    "for numeric array with NAs"    => { array: [Float::NAN, 1, 2, Float::NAN, 3], expected: [1, 2, 3] },
    "for string array with NAs"     => { array: [nil, "abc", nil, "xyz"]         , expected: ["abc", "xyz"] },
  )
  def test_drop_na(data)
    array, expected = data.values_at(:array, :expected)
    data = Numpy.asarray(array)
    vector = Charty::Vector.new(data)
    result = vector.drop_na
    assert_equal({
                   class: Charty::Vector,
                   data_class: Numpy::NDArray,
                   values: expected
                 },
                 {
                   class: result.class,
                   data_class: result.data.class,
                   values: result.data.to_a
                 })
  end

  def test_eq
    vector = Charty::Vector.new(Numpy.asarray(["a", "b", "c", "b", "d"], dtype: :str),
                                index: [10, 20, 30, 40, 50],
                                name: "foo")
    result = vector.eq("b")
    assert_equal({
                   class: Charty::Vector,
                   data_class: Numpy::NDArray,
                   data: [false, true, false, true, false],
                   index: [10, 20, 30, 40, 50],
                   name: "foo"
                 },
                 {
                   class: result.class,
                   data_class: result.data.class,
                   data: result.data.to_a,
                   index: result.index.to_a,
                   name: result.name
                 })
  end
end
