class IndexTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("#union") do
    sub_test_case("arrays") do
      def test_union
        index_a = Charty::Index.new([1, 2, 3, 4, 5])
        index_b = Charty::Index.new([4, 5, 6, 7, 8])
        assert_equal([
                       [1, 2, 3, 4, 5],
                       [1, 2, 3, 4, 5, 6, 7, 8],
                       [4, 5, 6, 7, 8, 1, 2, 3]
                     ],
                     [
                       index_a.union(index_a).values,
                       index_a.union(index_b).values,
                       index_b.union(index_a).values
                     ])
      end
    end

    sub_test_case("overlapped ranges") do
      def test_union
        index_a = Charty::RangeIndex.new(1 ... 10)
        index_b = Charty::RangeIndex.new(8 ..  20)
        assert_equal([
                       1 .. 20,
                       1 .. 20
                     ],
                     [
                       index_a.union(index_b).values,
                       index_b.union(index_a).values
                     ])
      end
    end

    sub_test_case("disjoint ranges") do
      def test_union
        index_a = Charty::RangeIndex.new(1 ... 5)
        index_b = Charty::RangeIndex.new(10 ... 15)
        assert_equal([
                       [1, 2, 3, 4, 10, 11, 12, 13, 14],
                       [10, 11, 12, 13, 14, 1, 2, 3, 4]
                     ],
                     [
                       index_a.union(index_b).values,
                       index_b.union(index_a).values
                     ])
      end
    end

    sub_test_case("array and range") do
      data(
        "case-1" => {
                      array: [1, 2, 3, 4, 5],
                      range: 4 .. 8
                    },
        "case-2" => {
                      range: 1 .. 5,
                      array: [4, 5, 6, 7, 8]
                    }
      )
      def test_union
        index_a = Charty::Index.new(data[:array])
        index_b = Charty::RangeIndex.new(data[:range])
        assert_equal([
                       Array,
                       data[:array].union(data[:range].to_a),
                       Array,
                       data[:range].to_a.union(data[:array]),
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("array and daru index") do
      data(
        "case-1" => {
                      array: [1, 2, 3, 4, 5],
                      daru: [4, 5, 6, 7, 8]
                    },
        "case-2" => {
                      daru: [1, 2, 3, 4, 5],
                      array: [4, 5, 6, 7, 8]
                    }
      )
      def test_union(data)
        index_a = Charty::Index.new(data[:array])
        index_b = Charty::DaruIndex.new(Daru::Index.new(data[:daru]))
        assert_equal([
                       Array,
                       data[:array].union(data[:daru]),
                       Array,
                       data[:daru].union(data[:array]),
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("range and daru index") do
      data(
        "case-1" => {
                      range: 1 .. 5,
                      daru: [4, 5, 6, 7, 8]
                    },
        "case-2" => {
                      daru: [1, 2, 3, 4, 5],
                      range: 4 .. 8
                    }
      )
      def test_union(data)
        index_a = Charty::RangeIndex.new(data[:range])
        index_b = Charty::DaruIndex.new(Daru::Index.new(data[:daru]))
        assert_equal([
                       Array,
                       data[:range].to_a.union(data[:daru]),
                       Array,
                       data[:daru].union(data[:range].to_a),
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("array and pandas num index") do
      data(
        "case-1" => { array: [1, 2, 3, 4, 5], pandas: [4, 5, 6, 7, 8] },
        "case-2" => { pandas: [1, 2, 3, 4, 5], array: [4, 5, 6, 7, 8] }
      )
      def test_union(data)
        pandas_required

        index_a = Charty::Index.new(data[:array])
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:array].union(data[:pandas]),
                       Pandas::Index,
                       data[:pandas].union(data[:array]),
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("range and pandas num index") do
      data(
        "overlapped case" => {
                               range: 1 .. 3,
                               pandas: [2, 3, 4, 5],
                               result_a: [1, 2, 3, 4, 5],
                               result_b: [2, 3, 4, 5, 1]
                             },
        "disjoint case"   => {
                               range: 6 .. 8,
                               pandas: [1, 2, 3, 4],
                               result_a: [6, 7, 8, 1, 2, 3, 4],
                               result_b: [1, 2, 3, 4, 6, 7, 8],
                             }
      )
      def test_union
        pandas_required

        index_a = Charty::RangeIndex.new(data[:range])
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:result_a],
                       Pandas::Index,
                       data[:result_b]
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("daru index and pandas num index") do
      data(
        "case-1" => {
                      daru: [1, 2, 3, 4, 5],
                      pandas: [4, 5, 6, 7, 8]
                    },
        "case-2" => {
                      pandas: [1, 2, 3, 4, 5],
                      daru: [4, 5, 6, 7, 8]
                    }
      )
      def test_union(data)
        pandas_required

        index_a = Charty::DaruIndex.new(Daru::Index.new(data[:daru]))
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:daru].union(data[:pandas]),
                       Pandas::Index,
                       data[:pandas].union(data[:daru]),
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("array and pandas range index") do
      data(
        "overlapped case" => {
                               array: [1, 2, 3],
                               pandas: 2 .. 5,
                               result_a: [1, 2, 3, 4, 5],
                               result_b: [2, 3, 4, 5, 1]
                             },
        "disjoint case"   => {
                               array: [6, 7, 8],
                               pandas: 1 .. 4,
                               result_a: [6, 7, 8, 1, 2, 3, 4],
                               result_b: [1, 2, 3, 4, 6, 7, 8]
                             }
      )
      def test_union
        pandas_required

        index_a = Charty::Index.new(data[:array])
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:result_a],
                       Pandas::Index,
                       data[:result_b]
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("range and pandas range index") do
      # NOTE: Using `sort=False` in pandas.Index#union does not produce pandas.RangeIndex.
      data(
        "overlapped case" => {
                               range: 1 .. 3,
                               pandas: 2 .. 5,
                               result_a: [1, 2, 3, 4, 5],
                               result_b: [2, 3, 4, 5, 1]
                             },
        "disjoint case"   => {
                               range: 6 .. 8,
                               pandas: 1 .. 4,
                               result_a: [6, 7, 8, 1, 2, 3, 4],
                               result_b: [1, 2, 3, 4, 6, 7, 8],
                             }
      )
      def test_union
        pandas_required

        index_a = Charty::RangeIndex.new(data[:range])
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:result_a],
                       Pandas::Index,
                       data[:result_b]
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end

    sub_test_case("daru and pandas range index") do
      data(
        "overlapped case" => {
                               daru: [1, 2, 3],
                               pandas: 2 .. 5,
                               result_a: [1, 2, 3, 4, 5],
                               result_b: [2, 3, 4, 5, 1]
                             },
        "disjoint case"   => {
                               daru: [6, 7, 8],
                               pandas: 1 .. 4,
                               result_a: [6, 7, 8, 1, 2, 3, 4],
                               result_b: [1, 2, 3, 4, 6, 7, 8]
                             }
      )
      def test_union
        pandas_required

        index_a = Charty::Index.new(Daru::Index.new(data[:daru]))
        index_b = Charty::PandasIndex.try_convert(data[:pandas])
        assert_equal([
                       Pandas::Index,
                       data[:result_a],
                       Pandas::Index,
                       data[:result_b]
                     ],
                     [
                       index_a.union(index_b).values.class,
                       index_a.union(index_b).to_a,
                       index_b.union(index_a).values.class,
                       index_b.union(index_a).to_a
                     ])
      end
    end
  end
end
