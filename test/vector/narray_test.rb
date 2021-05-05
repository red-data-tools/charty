class VectorNArrayTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    numo_required

    @classes = {
      DFloat:  Numo::DFloat,
      RObject: Numo::RObject
    }
    @data = Numo::DFloat[1, 2, 3, 4, 5]
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
  end

  test("#to_a") do
    assert_equal([1, 2, 3, 4, 5],
                 @vector.to_a)
  end

  test("#data") do
    assert_equal({
                   class: Numo::DFloat,
                   value: Numo::DFloat[1, 2, 3, 4, 5]
                 },
                 {
                   class: @vector.data.class,
                   value: @vector.data
                 })
  end

  sub_test_case("#numeric?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , dtype: :DFloat , result: true },
      "for string array"                   => { array: ["abc", "def", "xyz"] , dtype: :RObject, result: false },
      "for numeric array with nil at head" => { array: [Float::NAN, 1, 2, 3] , dtype: :DFloat , result: true },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , dtype: :RObject, result: false },
    )
    def test_numeric(data)
      array, dtype, result = data.values_at(:array, :dtype, :result)
      data = @classes[dtype][*array]
      vector = Charty::Vector.new(data)
      assert_equal(result, vector.numeric?)
    end
  end

  sub_test_case("#categorical?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]      , dtype: :DFloat  },
      "for string array"                   => { array: ["abc", "def", "xyz"], dtype: :RObject },
      "for numeric array with nil at head" => { array: [Float::NAN, 1, 2, 3], dtype: :DFloat  },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]  , dtype: :RObject }
    )
    def test_categorical(data)
      array, dtype = data.values_at(:array, :dtype)
      data = @classes[dtype][*array]
      vector = Charty::Vector.new(data)
      assert do
        not vector.categorical?
      end
    end
  end

  sub_test_case("#categories") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , dtype: :DFloat },
      "for string array"                   => { array: ["abc", "def", "xyz"] , dtype: :RObject },
      "for numeric array with nil at head" => { array: [Float::NAN, 1, 2, 3] , dtype: :DFloat },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , dtype: :RObject },
    )
    def test_categories(data)
      array, dtype = data.values_at(:array, :dtype)
      data = @classes[dtype][*array]
      vector = Charty::Vector.new(data)
      assert_nil(vector.categories)
    end
  end

  sub_test_case("#unique_values") do
    def setup
      super
      @data = Numo::Int64[3, 1, 3, 2, 1]
      @vector = Charty::Vector.new(@data)
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
  end

  test("#group_by") do
    vector = Charty::Vector.new(Numo::Int64[1, 2, 3, 4, 5])
    grouper = Charty::Vector.new(Numo::RObject["a", "b", "a", "a", "b"])
    result = vector.group_by(grouper)
    assert_equal({
                   classes: { "a" => Charty::Vector       , "b" => Charty::Vector },
                   data:    { "a" => Numo::Int64[1, 3, 4] , "b" => Numo::Int64[2, 5] }
                 },
                 {
                   classes: { "a" => result["a"].class, "b" => result["b"].class },
                   data:    { "a" => result["a"].data , "b" => result["b"].data }
                 })
  end

  data(
    "for numeric array without NA"  => { array: [1, 2, 3, 4, 5]                  , dtype: :DFloat , expected: [1, 2, 3, 4, 5] },
    "for string array without NA"   => { array: ["abc", "def", "xyz"]            , dtype: :RObject, expected: ["abc", "def", "xyz"] },
    "for numeric array with NAs"    => { array: [Float::NAN, 1, 2, Float::NAN, 3], dtype: :DFloat , expected: [1, 2, 3] },
    "for string array with NAs"     => { array: [nil, "abc", Float::NAN, "xyz"]  , dtype: :RObject, expected: ["abc", "xyz"] },
  )
  def test_drop_na(data)
    array, dtype, expected = data.values_at(:array, :dtype, :expected)
    vector = Charty::Vector.new(@classes[dtype][*array])
    result = vector.drop_na
    assert_equal({
                   class: Charty::Vector,
                   values: @classes[dtype][*expected]
                 },
                 {
                   class: result.class,
                   values: result.data
                 })
  end

  def test_eq
    vector = Charty::Vector.new(Numo::RObject["a", "b", "c", "b", "d"],
                                index: [10, 20, 30, 40, 50],
                                name: "foo")
    result = vector.eq("b")
    assert_equal({
                   class: Charty::Vector,
                   data_class: Numo::Bit,
                   data: [0, 1, 0, 1, 0],
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
