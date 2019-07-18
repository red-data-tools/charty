module Charty
  module TableAdapters
    class ActiveRecordAdapter
      include Enumerable

      def self.make(data)
        self.new(data)
      end

      def self.supported?(data)
        defined?(ActiveRecord::Relation) && data.is_a?(ActiveRecord::Relation)
      end

      def initialize(data)
        @data = check_type(ActiveRecord::Relation, data, :data)
        @columns = @data.column_names.freeze
        @records = nil
      end

      attr_reader :columns

      def [](i, j)
        fetch_records unless @records

        col = columns.index(j)
        unless col 
          raise IndexError, "Invalid column index: #{j}"
        end

        @records[i][col]
      end

      private def fetch_records
        @records = @data.pluck(*columns)
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end

    register(:active_record, ActiveRecordAdapter)
  end
end
