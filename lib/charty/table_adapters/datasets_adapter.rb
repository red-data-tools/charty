module Charty
  module TableAdapters
    class DatasetsAdapter
      include Enumerable

      def self.supported?(data)
        defined?(Datasets::Dataset) &&
          data.is_a?(Datasets::Dataset) &&
          data.class.const_defined?(:Record)
      end

      def initialize(dataset)
        @dataset = dataset
        @records = []
      end

      def column_names
        @dataset.class::Record.members
      end

      def each(&block)
        return to_enum(__method__) unless block_given?

        fetch_all if @records.empty?
        @records.each(&block)
      end

      private def fetch_all
        @dataset.each do |record|
          @records << record
        end
      end

      # @param [Integer] row  Row index
      # @param [Symbol,String,Integer] column Column index
      def [](row, column)
        fetch_all if @records.empty?
        if row
          @records[row][column]
        else
          @records.map {|record| record[column] }
        end
      end
    end

    register(:datasets, DatasetsAdapter)
  end
end
