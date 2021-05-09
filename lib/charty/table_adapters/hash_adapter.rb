require 'date'

module Charty
  module TableAdapters
    class HashAdapter < BaseAdapter
      TableAdapters.register(:hash, self)

      def self.supported?(data)
        case data
        when []
          true
        when Array
          case data[0]
          when Numeric, String, Time, Date
            true
          when Hash
            data.all? {|el| el.is_a? Hash }
          when method(:array?)
            data.all?(&method(:array?))
          end
        when Hash
          true
        end
      end

      def self.array?(data)
        case data
        when Charty::Vector
          true
        when Array,
             ->(x) { defined?(Numo::NArray) && x.is_a?(Numo::NArray) },
             ->(x) { defined?(Daru::Vector) && x.is_a?(Daru::Vector) },
             ->(x) { defined?(NMatrix) && x.is_a?(NMatrix) }
          true
        else
          false
        end
      end

      def initialize(data, columns: nil, index: nil)
        case data
        when Hash
          @data = data
          if columns
            # TODO: replace columns
          end
        when Array
          case data[0]
          when Numeric, String, Time, Date
            data = data.map {|x| [x] }
            @data = make_data_from_records(data, columns)
          when Hash
            # TODO
          when self.class.method(:array?)
            unsupported_data_format unless data.all?(&self.class.method(:array?))
            @data = make_data_from_records(data, columns)
          else
            unsupported_data_format
          end
        else
          unsupported_data_format
        end

        self.columns = columns || Index.new(@data.keys)
        self.index = index || RangeIndex.new(0 ... length)
      end

      attr_reader :data

      def_delegator :@data, :keys, :column_names

      def length
        case
        when column_names.empty?
          0
        else
          data[column_names[0]].size
        end
      end

      def column_length
        data.length
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          Vector.new(@data[column], name: column)
        end
      end

      def each
        i, n = 0, shape[0]
        while i < n
          record = @data.map {|k, v| v[i] }
          yield record
          i += 1
        end
      end

      private def make_data_from_records(data, columns)
        n_rows = data.length
        n_columns = data.map(&:size).max
        columns = generate_column_names(n_columns, columns)
        columns.map.with_index { |key, j|
          values = n_rows.times.map {|i| data[i][j] }
          [key, values]
        }.to_h
      end

      private def generate_column_names(n_columns, columns)
        # FIXME: this is the same as NArrayAdapter#generate_column_names
        columns ||= []
        if columns.length >= n_columns
          columns[0, n_columns]
        else
          columns + columns.length.upto(n_columns - 1).map {|i| "X#{i}" }
        end
      end

      private def unsupported_data_format
        raise ArgumentError, "Unsupported data format"
      end
    end
  end
end
