module Charty
  module TableAdapters
    class DatasetsAdapter
      extend Forwardable
      include Enumerable

      def self.make(dataset)
        GenericDatasetsAdapter.new(dataset)
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

      # @param [Integer] i  Row index
      # @param [Symbol,String,Integer] j  Column index
      def [](i, j)
        fetch_all if @records.empty?
        @records[i][j]
      end

      class GenericDatasetsAdapter < self
        def columns
          @dataset.class::Record.members
        end
      end
    end
  end
end
