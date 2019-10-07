$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'charty'
require 'test/unit'
require 'tempfile'
begin
  require 'cv'
rescue LoadError
end


module Helper
  module Image
    def assert_image(expected_path, actual_path)
      unless defined?(::CV)
        omit("red-opencv is required for #{__method__}")
      end
      expected = CV::Image.read(expected_path)
      actual = CV::Image.read(actual_path)
      # TODO: Make this loose
      assert_equal(expected.bytes.to_s,
                   actual.bytes.to_s)
    end
  end
end
