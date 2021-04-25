module Charty
  module VectorAdapters
    class NMatrixAdapter < BaseAdapter
      VectorAdapters.register(:nmatrix, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(NMatrix) && data.is_a?(NMatrix)
      end

      def initialize(data)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      include NameSupport
      include IndexSupport

      alias length size
    end
  end
end
