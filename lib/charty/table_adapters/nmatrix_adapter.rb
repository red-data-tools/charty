module Charty
  module TableAdapters
    class NMatrixAdapter
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
        @column_names = generate_column_names(data.shape[1], columns)
      end

      attr_reader :column_names

      def [](row, column)
        if row
          @data[row, resolve_column_index(column)]
        else
          @data[:*, resolve_column_index(column)].reshape([@data.shape[0]])
        end
      end

      private def resolve_column_index(column)
        case column
        when String
          index = column_names.index(column)
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

    register(:nmatrix, NMatrixAdapter)
  end
end
