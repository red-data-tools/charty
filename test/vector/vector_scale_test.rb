class VectorScaleTest < Test::Unit::TestCase
  include Charty::TestHelpers

  sub_test_case("linear") do
    data(:adapter_type, [:array, :daru, :narray, :nmatrix, :numpy, :pandas], keep: true)
    def test_scale_linear(data)
      omit("TODO")
    end

    def test_scale_inverse_linear(data)
      omit("TODO")
    end
  end

  sub_test_case("log") do
    data(:adapter_type, [:array, :daru, :narray, :nmatrix, :numpy, :pandas], keep: true)
    def test_scale_log(data)
      omit("TODO")
    end

    def test_scale_inverse_log(data)
      omit("TODO")
    end
  end
end
