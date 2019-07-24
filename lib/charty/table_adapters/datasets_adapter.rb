module Charty
  module TableAdapters
    class DatasetsAdapter
      extend Forwardable
      include Enumerable

      def self.make(dataset)
        case
        when dataset.class.const_defined?(:Record)
          RecordCollectionAdapter.new(dataset)
        else
          raise TypeError, "Unsupported dataset class: #{dataset.class}"
        end
      end

      def self.supported?(data)
        defined?(Datasets::Dataset) && data.is_a?(Datasets::Dataset)
      end

      def initialize(dataset)
        @dataset = dataset
        @records = []
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

      class RecordCollectionAdapter < self
        def columns
          @dataset.class::Record.members
        end
      end
    end

    register(:datasets, DatasetsAdapter)
  end
end
