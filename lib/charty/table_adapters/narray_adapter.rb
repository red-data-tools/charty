module Charty
  module TableAdapters
    class NArrayAdapter
      def self.supported?(data)
        defined?(Numo::NArray) && data.is_a?(Numo::NArray) && data.ndim <= 2
      end

      def initialize(data, columns: nil)
        case data.ndim
        when 1
          data = data.reshape(data.length, 1)
        when 2
          # do nothing
        else
          raise ArgumentError, "Unsupported data format"
        end
        @data = data
        @column_names = generate_column_names(data.shape[1], columns)
      end

      attr_reader :column_names

      def column(i)
        @data[true, column_index(i)]
      end

      def [](i, j)
        @data[i, column_index(j)]
      end

      private def column_index(name)
        index = column_names.index(name)
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

    register(:narray, NArrayAdapter)
  end
end
