require "forwardable"

module Charty
  module TableAdapters
    class PandasDataFrameAdapter < BaseAdapter
      TableAdapters.register(:pandas_data_frame, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(Pandas::DataFrame) && data.is_a?(Pandas::DataFrame)
      end

      def initialize(data, columns: nil, index: nil)
        @data = check_type(Pandas::DataFrame, data, :data)

        self.columns = columns unless columns.nil?
        self.index = index unless index.nil?
      end

      attr_reader :data

      def length
        data.shape[0]
      end

      def columns
        PandasIndex.new(data.columns)
      end

      def columns=(new_columns)
        case new_columns
        when PandasIndex
          data.columns = new_columns.values
          data.columns.name = new_columns.name
        when Index
          data.columns = new_columns.to_a
          data.columns.name = new_columns.name
        else
          data.columns = new_columns
        end
      end

      def index
        PandasIndex.new(data.index)
      end

      def index=(new_index)
        case new_index
        when PandasIndex
          data.index = new_index.values
          data.index.name = new_index.name
        when Index
          data.index = new_index.to_a
          data.index.name = new_index.name
        else
          data.index = new_index
        end
      end

      def column_names
        @data.columns.to_a
      end

      def compare_data_equality(other)
        case other
        when PandasDataFrameAdapter
          data.equals(other.data)
        else
          super
        end
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          Vector.new(@data[column])
        end
      end

      def drop_na
        Charty::Table.new(@data.dropna)
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end

      class GroupBy < Charty::Table::GroupByBase
        def initialize(groupby)
          @groupby = groupby
        end

        def indices
          @groupby.indices.map { |k, v|
            [k, v.to_a]
          }.to_h
        end

        def apply(*args, &block)
          res = @groupby.apply(->(data) {
            res = block.call(Charty::Table.new(data), *args)
            Pandas::Series.new(data: res)
          })
          Charty::Table.new(res)
        end
      end

      def group_by(_table, grouper, sort)
        GroupBy.new(@data.groupby(by: grouper, sort: sort))
      end
    end
  end
end
