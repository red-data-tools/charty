require "forwardable"

module Charty
  module TableAdapters
    class BaseAdapter
      extend Forwardable
      include Enumerable

      attr_reader :columns

      def columns=(values)
        @columns = check_and_convert_index(values, :columns, column_length)
      end

      def column_names
        columns.to_a
      end

      attr_reader :index

      def index=(values)
        @index = check_and_convert_index(values, :index, length)
      end

      def ==(other)
        case other
        when BaseAdapter
          return false if columns != other.columns
          return false if index != other.index
          compare_data_equality(other)
        else
          false
        end
      end

      def compare_data_equality(other)
        columns.each do |name|
          if self[nil, name] != other[nil, name]
            return false
          end
        end
        true
      end

      private def check_and_convert_index(values, name, expected_length)
        case values
        when Index, Range
        else
          unless (ary = Array.try_convert(values))
            raise ArgumentError, "invalid object for %s: %p" % [name, values]
          end
          values = ary
        end
        if expected_length != values.size
          raise ArgumentError,
                "invalid length for %s (%d for %d)" % [name, values.size, expected_length]
        end
        case values
        when Index
          values
        when Range
          RangeIndex.new(values)
        when Array
          Index.new(values)
        end
      end
    end
  end
end
