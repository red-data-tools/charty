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
        @columns = generate_column_names(data.shape[1], columns)
      end

      attr_reader :columns

      def column(i)
        @data[:*, column_index(i)].reshape([@data.shape[0]])
      end

      def [](i, j)
        @data[i, column_index(j)]
      end

      private def column_index(name)
        index = columns.index(name)
        return index if index
        raise IndexError, "Invalid column name: #{name}"
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
