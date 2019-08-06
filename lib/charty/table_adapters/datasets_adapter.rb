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

      def columns
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

      def column(i)
        fetch_all if @records.empty?
        @records.map {|record| record[i] }
      end

      # @param [Integer] i  Row index
      # @param [Symbol,String,Integer] j  Column index
      def [](i, j)
        fetch_all if @records.empty?
        @records[i][j]
      end
    end

    register(:datasets, DatasetsAdapter)
  end
end
