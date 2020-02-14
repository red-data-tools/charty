$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'charty'
require 'test/unit'

module TestHelper
  def assert_near(c1, c2, eps=1e-8)
    assert_equal(c1.class, c2.class)
    c1.components.zip(c2.components).each do |x1, x2|
      x1, x2 = [x1, x2].map(&:to_f)
      assert { (x1 - x2).abs < eps }
    end
  end
end
