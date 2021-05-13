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

      def compare_data_equality(other)
        case other
        when NMatrixAdapter
          data == other.data
        when ArrayAdapter, DaruVectorAdapter
          data.to_a == other.data.to_a
        when NArrayAdapter, NumpyAdapter, PandasSeriesAdapter
          other.compare_data_equality(self)
        else
          data == other.data.to_a
        end
      end

      include NameSupport
      include IndexSupport

      alias length size
    end
  end
end
