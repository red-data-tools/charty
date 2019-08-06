module Charty
  module TableAdapters
    class ActiveRecordAdapter
      include Enumerable

      def self.supported?(data)
        defined?(ActiveRecord::Relation) && data.is_a?(ActiveRecord::Relation)
      end

      def initialize(data)
        @data = check_type(ActiveRecord::Relation, data, :data)
        @column_names = @data.column_names.freeze
        @arrays = nil
      end

      attr_reader :column_names

      def column(i)
        col = column_names.index(i)
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
        @arrays = @data.pluck(*column_names).transpose
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end

    register(:active_record, ActiveRecordAdapter)
  end
end
