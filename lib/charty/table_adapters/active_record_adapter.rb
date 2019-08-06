module Charty
  module TableAdapters
    class ActiveRecordAdapter
      include Enumerable

      def self.supported?(data)
        defined?(ActiveRecord::Relation) && data.is_a?(ActiveRecord::Relation)
      end

      def initialize(data)
        @data = check_type(ActiveRecord::Relation, data, :data)
        @columns = @data.column_names.freeze
        @arrays = nil
      end

      attr_reader :columns

      def column(i)
        col = columns.index(i)
        if col
          fetch_records unless @arrays
          @arrays[col]
        else
          raise IndexError, "Invalid column index: #{i}"
        end
      end

      def [](i, j)
        column(j)[i]
      end

      private def fetch_records
        @arrays = @data.pluck(*columns).transpose
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end

    register(:active_record, ActiveRecordAdapter)
  end
end
