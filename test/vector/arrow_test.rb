class VectorArrowTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    arrow_required

    @data = Arrow::Array.new([1, 2, nil, 4, 2])
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
        assert_equal({
                       class: Charty::RangeIndex,
                       length: 5,
                       values: [0, 1, 2, 3, 4],
                     },
                     {
                       class: @vector.index.class,
                       length: @vector.index.length,
                       values: @vector.index.to_a
                     })
      end
    end

    sub_test_case("with string index") do
      def test_index
        @vector.index = ["a", "b", "c", "d", "e"]
        assert_equal({
                       class: Charty::Index,
                       length: 5,
                       values: ["a", "b", "c", "d", "e"],
                     },
                     {
                       class: @vector.index.class,
                       length: @vector.index.length,
                       values: @vector.index.to_a
                     })
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
                       nil,
                       4,
                       2,
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

      data(:mask_adapter,
           [
             :array,
             :daru,
             :narray,
             :narray_bool_obj,
             :numpy,
             :numpy_bool_obj,
             :pandas,
             :pandas_bool_obj,
           ])
      def test_aref_with_mask(data)
        mask_adapter = data[:mask_adapter]
        send("setup_#{mask_adapter}_mask")
        @vector.index = [10, 20, 30, 40, 50]
        @vector.name = "name"
        result = @vector[@mask]
        assert_equal({
                       class: Charty::Vector,
                       data_class: Arrow::UInt8Array,
                       values: [2, 4],
                       index: [20, 40],
                       name: "name",
                     },
                     {
                       class: result.class,
                       data_class: result.data.class,
                       values: result.data.to_a,
                       index: result.index.to_a,
                       name: result.name,
                     })
      end
    end
  end

  test("#to_a") do
    assert_equal([1, 2, nil, 4, 2],
                 @vector.to_a)
  end

  test("#data") do
    assert_equal({
                   class: Arrow::UInt8Array,
                   value: Arrow::Array.new([1, 2, nil, 4, 2]),
                 },
                 {
                   class: @vector.data.class,
                   value: @vector.data,
                 })
  end

  sub_test_case("#boolean?") do
    def test_boolean_array
      data = Arrow::BooleanArray.new([true, false])
      vector = Charty::Vector.new(data)
      assert do
        vector.boolean?
      end
    end

    def test_numeric_array
      assert do
        not @vector.boolean?
      end
    end
  end

  sub_test_case("#numeric?") do
    def test_boolean_array
      data = Arrow::BooleanArray.new([true, false])
      vector = Charty::Vector.new(data)
      assert do
        not vector.numeric?
      end
    end

    def test_numeric_array
      assert do
        @vector.numeric?
      end
    end
  end

  sub_test_case("#categorical?") do
    def test_numeric_array
      assert do
        not @vector.categorical?
      end
    end

    def test_dictionary_array
      data = Arrow::Array.new([:a, :a, :b, :a, :c])
      vector = Charty::Vector.new(data)
      assert do
        vector.categorical?
      end
    end
  end

  def test_categories
    data = Arrow::Array.new([:a, :a, :b, :a, :c])
    vector = Charty::Vector.new(data)
    assert_equal(["a", "b", "c"],
                 vector.categories)
  end

  def test_unique_values
    result = @vector.unique_values
    assert_equal({
                   class: Array,
                   values: @data.to_a.uniq
                 },
                 {
                   class: result.class,
                   values: result
                 })
  end

  test("#group_by") do
    grouper = Charty::Vector.new(Arrow::Array.new(["a", "b", "a", "a", "b"]))
    result = @vector.group_by(grouper)
    assert_equal({
                   classes: {
                     "a" => Charty::Vector,
                     "b" => Charty::Vector,
                   },
                   data: {
                     "a" => Arrow::UInt8Array.new([1, nil, 4]),
                     "b" => Arrow::UInt8Array.new([2, 2]),
                   },
                 },
                 {
                   classes: {
                     "a" => result["a"].class,
                     "b" => result["b"].class,
                   },
                   data: {
                     "a" => result["a"].data,
                     "b" => result["b"].data,
                   },
                 })
  end

  sub_test_case("#drop_na") do
    def test_have_null
      result = @vector.drop_na
      assert_equal({
                     class: Charty::Vector,
                     values: Arrow::Array.new(@data.to_a.compact),
                   },
                   {
                     class: result.class,
                     values: result.data
                   })
    end

    def test_no_null
      data = Arrow::Array.new([1, 2, 3, 4, 5])
      vector = Charty::Vector.new(data)
      result = vector.drop_na
      assert_equal({
                     class: Charty::Vector,
                     values: Arrow::Array.new(data.to_a.compact),
                   },
                   {
                     class: result.class,
                     values: result.data
                   })
    end
  end

  def test_eq
    vector = Charty::Vector.new(@data,
                                index: [10, 20, 30, 40, 50],
                                name: "name")
    result = vector.eq(2)
    assert_equal({
                   class: Charty::Vector,
                   data_class: Arrow::BooleanArray,
                   data: [false, true, nil, false, true],
                   index: [10, 20, 30, 40, 50],
                   name: "name"
                 },
                 {
                   class: result.class,
                   data_class: result.data.class,
                   data: result.data.to_a,
                   index: result.index.to_a,
                   name: result.name
                 })
  end

  sub_test_case("#notnull") do
    def test_have_null
      index = @data.length.times.map.with_index {|i| i*100 }
      result = Charty::Vector.new(@data, index: index, name: "name").notnull
      assert_equal({
                     class: Charty::Vector,
                     boolean_p: true,
                     data_class: Arrow::BooleanArray,
                     data: Arrow::BooleanArray.new([true, true, false, true, true]),
                     index_values: index,
                     name: "name"
                   },
                   {
                     class: result.class,
                     boolean_p: result.boolean?,
                     data_class: result.data.class,
                     data: result.data,
                     index_values: result.index.to_a,
                     name: result.name
                   })
    end

    def test_no_null
      data = Arrow::Array.new([1, 2, 3, 4, 5])
      vector = Charty::Vector.new(data)
      index = data.length.times.map.with_index {|i| i*100 }
      result = Charty::Vector.new(data, index: index, name: "name").notnull
      assert_equal({
                     class: Charty::Vector,
                     boolean_p: true,
                     data_class: Arrow::BooleanArray,
                     data: Arrow::BooleanArray.new([true, true, true, true, true]),
                     index_values: index,
                     name: "name"
                   },
                   {
                     class: result.class,
                     boolean_p: result.boolean?,
                     data_class: result.data.class,
                     data: result.data,
                     index_values: result.index.to_a,
                     name: result.name
                   })
    end
  end
end
