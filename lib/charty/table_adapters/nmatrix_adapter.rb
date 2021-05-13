module Charty
  module TableAdapters
    class NMatrixAdapter < BaseAdapter
      TableAdapters.register(:nmatrix, self)

      def self.supported?(data)
        defined?(NMatrix) && data.is_a?(NMatrix) && data.shape.length <= 2
      end

      def initialize(data, columns: nil)
        case data.shape.length
        when 1
          data = data.reshape(data.size, 1)
        when 2
          # do nothing
        else
          raise ArgumentError, "Unsupported data format"
        end
        @data = data
        self.columns = Index.new(generate_column_names(data.shape[1], columns))
        self.index = index || RangeIndex.new(0 ... length)
      end

      attr_reader :data

      def length
        data.shape[0]
      end

      def column_length
        data.shape[1]
      end

      def [](row, column)
        if row
          @data[row, resolve_column_index(column)]
        else
          column_data = @data[:*, resolve_column_index(column)].reshape([@data.shape[0]])
          Charty::Vector.new(column_data, index: index, name: column)
        end
      end

      private def resolve_column_index(column)
        case column
        when String, Symbol
          index = column_names.index(column.to_sym) || column_names.index(column.to_s)
          return index if index
          raise IndexError, "invalid column name: #{column}"
        when Integer
          column
        else
          message = "column must be String or Integer: #{column.inspect}"
          raise ArgumentError, message
        end
      end

      private def generate_column_names(n_columns, columns)
        columns ||= []
        if columns.length >= n_columns
          columns[0, n_columns]
        else
          columns + columns.length.upto(n_columns - 1).map {|i| "X#{i}" }
        end
      end
    end
  end
end
