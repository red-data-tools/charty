$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "charty"
require "test/unit"

require "daru"

begin
  require "numo/narray"
rescue LoadError
end

begin
  require "nmatrix"
rescue LoadError
end

begin
  require "matplotlib"
rescue LoadError
end

module Charty
  module TestHelpers
    module_function def numo_available?
      defined?(::Numo::NArray)
    end

    module_function def numo_required
      omit("Numo::NArray is requried") unless numo_available?
    end

    module_function def nmatrix_available?
      defined?(::NMatrix::VERSION::STRING)
    end

    module_function def nmatrix_required
      omit("NMatrix is requried") unless nmatrix_available?
    end

    module_function def matplotlib_available?
      @matplotlib_available
    end

    module_function def matplotlib_required
      defined?(::Matplotlib)
    end

    def assert_near(c1, c2, eps=1e-8)
      assert_equal(c1.class, c2.class)
      c1.components.zip(c2.components).each do |x1, x2|
        x1, x2 = [x1, x2].map(&:to_f)
        assert { (x1 - x2).abs < eps }
      end
    end
  end
end
