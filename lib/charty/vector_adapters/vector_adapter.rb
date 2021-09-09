module Charty
  module VectorAdapters
    class VectorAdapter < BaseAdapter
      VectorAdapters.register(:vector, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        data.is_a?(Vector)
      end

      def initialize(data, index: nil)
        data = check_data(data)
        @data = reduce_nested_vector(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      include NameSupport
      include IndexSupport

      def_delegators :data,
                     :boolean?,
                     :categorical?,
                     :categories,
                     :drop_na,
                     :each,
                     :eq,
                     :first_nonnil,
                     :group_by,
                     :notnull,
                     :numeric?,
                     :to_a,
                     :uniq,
                     :unique_values,
                     :values_at,
                     :where

      def compare_data_equality(other)
        if other.is_a?(self.class)
          other = reduce_nested_vector(other.data).adapter
        end
        if other.is_a?(self.class)
          @data.adapter.data == other.data
        elsif @data.adapter.respond_to?(:compare_data_equality)
          @data.adapter.compare_data_equality(other)
        elsif other.respond_to?(:compare_data_equality)
          other.compare_data_equality(@data.adapter)
        else
          @data.adapter.to_a == other.to_a
        end
      end

      private def reduce_nested_vector(vector)
        while vector.adapter.is_a?(self.class)
          vector = vector.adapter.data
        end
        vector
      end
    end
  end
end
