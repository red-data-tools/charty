module Charty
  module TableAdapters
    class ArrowAdapter < BaseAdapter
      TableAdapters.register(:arrow, self)

      def self.supported?(data)
        defined?(Arrow::Table) && data.is_a?(Arrow::Table)
      end

      def initialize(data)
        @data = data
        @column_names = @data.columns.map(&:name)
        self.columns = Index.new(@column_names)
        self.index = RangeIndex.new(0 ... length)
      end

      attr_reader :data

      def length
        @data.n_rows
      end

      def column_length
        @column_names.length
      end

      def compare_data_equality(other)
        case other
        when ArrowAdapter
          data == other.data
        else
          super
        end
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          case column
          when Array
            Table.new(@data.select_columns(*column))
          else
            column_data = @data[column]
            Vector.new(column_data.data.combine,
                       index: index,
                       name: column_data.name)
          end
        end
      end
    end
  end
end
