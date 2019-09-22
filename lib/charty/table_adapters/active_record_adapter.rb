module Charty
  module TableAdapters
    class ActiveRecordAdapter
      TableAdapters.register(:active_record, self)

      include Enumerable

      def self.supported?(data)
        defined?(ActiveRecord::Relation) && data.is_a?(ActiveRecord::Relation)
      end

      def initialize(data)
        @data = check_type(ActiveRecord::Relation, data, :data)
        @column_names = @data.column_names.freeze
        @columns = nil
      end

      attr_reader :column_names

      def [](row, column)
        fetch_records unless @columns
        if row
          @columns[resolve_column_index(column)][row]
        else
          @columns[resolve_column_index(column)]
        end
      end

      private def resolve_column_index(column)
        case column
        when String, Symbol
          index = column_names.index(column.to_s)
          unless index
            raise IndexError, "invalid column name: #{column.inspect}"
          end
          index
        when Integer
          column
        else
          message = "column must be String or Integer: #{column.inspect}"
          raise ArgumentError, message
        end
      end

      private def fetch_records
        @columns = @data.pluck(*column_names).transpose
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
