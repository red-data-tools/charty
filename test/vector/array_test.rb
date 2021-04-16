class VectorArrayTest < Test::Unit::TestCase
  def setup
    @data = [1, 2, 3, 4, 5]
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

  sub_test_case("#numeric?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , result: true },
      "for string array"                   => { array: ["abc", "def", "xyz"] , result: false },
      "for numeric array with nil at head" => { array: [nil, 1, 2, 3]        , result: true },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , result: false },
    )
    def test_numeric(data)
      array, result = data.values_at(:array, :result)
      vector = Charty::Vector.new(array)
      assert_equal(result, vector.numeric?)
    end
  end

  sub_test_case("#categorical?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , result: false },
      "for string array"                   => { array: ["abc", "def", "xyz"] , result: false },
      "for numeric array with nil at head" => { array: [nil, 1, 2, 3]        , result: false },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , result: false },
    )
    def test_numeric(data)
      array, result = data.values_at(:array, :result)
      vector = Charty::Vector.new(array)
      assert_equal(result, vector.categorical?)
    end
  end

  sub_test_case("#categories") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , result: nil },
      "for string array"                   => { array: ["abc", "def", "xyz"] , result: nil },
      "for numeric array with nil at head" => { array: [nil, 1, 2, 3]        , result: nil },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , result: nil },
    )
    def test_numeric(data)
      array, result = data.values_at(:array, :result)
      vector = Charty::Vector.new(array)
      assert_equal(result, vector.categories)
    end
  end

  sub_test_case("#unique_values") do
    def setup
      @data = [3, 1, 3, 2, 1]
      @vector = Charty::Vector.new(@data)
    end

    def test_unique_values
      result = @vector.unique_values
      assert_equal({
                     class: Array,
                     values: @data.uniq
                   },
                   {
                     class: result.class,
                     values: result
                   })
    end
  end

  test("#group_by") do
    vector = Charty::Vector.new([1, 2, 3, 4, 5])
    grouper = Charty::Vector.new(["a", "b", "a", "a", "b"])
    result = vector.group_by(grouper)
    assert_equal({
                   classes: { "a" => Charty::Vector, "b" => Charty::Vector },
                   data:    { "a" => [1, 3, 4]     , "b" => [2, 5] }
                 },
                 {
                   classes: { "a" => result["a"].class, "b" => result["b"].class },
                   data:    { "a" => result["a"].data , "b" => result["b"].data }
                 })
  end

  data(
    "for numeric array without NA"  => { array: [1, 2, 3, 4, 5]           , expected: [1, 2, 3, 4, 5] },
    "for string array without NA"   => { array: ["abc", "def", "xyz"]     , expected: ["abc", "def", "xyz"] },
    "for numeric array with NAs"    => { array: [nil, 1, 2, Float::NAN, 3], expected: [1, 2, 3] },
    "for string array with NAs"     => { array: [nil, "abc", nil, "xyz"]  , expected: ["abc", "xyz"] },
  )
  def test_drop_na(data)
    array, expected = data.values_at(:array, :expected)
    vector = Charty::Vector.new(array)
    result = vector.drop_na
    assert_equal({
                   class: Charty::Vector,
                   values: expected
                 },
                 {
                   class: result.class,
                   values: result.data
                 })
  end
end
