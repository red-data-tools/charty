module Charty
  module VectorAdapters
    class NArrayAdapter < BaseAdapter
      VectorAdapters.register(:narray, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(Numo::NArray) && data.is_a?(Numo::NArray)
      end

      def initialize(data)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      include NameSupport
      include IndexSupport
    end
  end
end
