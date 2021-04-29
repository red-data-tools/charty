module Charty
  module TableAdapters
    class DatasetsAdapter
      TableAdapters.register(:datasets, self)

      include Enumerable

      def self.supported?(data)
        defined?(Datasets::Dataset) &&
          data.is_a?(Datasets::Dataset)
      end

      def initialize(dataset)
        @table = dataset.to_table
        @records = []
      end

      def data
        @table
      end

      def column_names
        @table.column_names
      end

      def each(&block)
        return to_enum(__method__) unless block_given?

        @table.each_record(&block)
      end

      # @param [Integer] row  Row index
      # @param [Symbol,String,Integer] column Column index
      def [](row, column)
        if row
          record = @table.find_record(row)
          return nil if record.nil?
          record[column]
        else
          Vector.new(@table[column], name: column)
        end
      end
    end
  end
end
