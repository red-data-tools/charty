class VectorPandasTest < Test::Unit::TestCase
  def setup
    begin
      require "pandas"
    rescue LoadError
      omit("pandas is unavailable")
    end

    @series = Pandas::Series.new([1, 2, 3, 4, 5], dtype: :float64)
    @vector = Charty::Vector.new(@series)
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
        @series.index = ["a", "b", "c", "d", "e"]
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
        @series.index = ["a", "b", "c", "d", "e"]
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
end
