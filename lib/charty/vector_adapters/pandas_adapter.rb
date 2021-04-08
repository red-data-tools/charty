module Charty
  module VectorAdapters
    class PandasSeriesAdapter < BaseAdapter
      VectorAdapters.register(:pandas_series, self)

      def self.supported?(data)
        return false unless defined?(Pandas::Series)
        case data
        when Pandas::Series
          true
        else
          false
        end
      end

      def initialize(data)
        @data = check_data(data)
      end

      attr_reader :data

      def_delegator :data, :size, :length
      def_delegators :data, :index, :index=
      def_delegators :data, :name, :name=
      def_delegators :data, :[], :[]=
    end
  end
end
