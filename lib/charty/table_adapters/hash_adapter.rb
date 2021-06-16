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
        # TODO: Use vector adapter to detect them:
        when Array, method(:daru_vector?), method(:narray_vector?), method(:nmatrix_vector?),
             method(:numpy_vector?), method(:pandas_series?)
          true
        else
          false
        end
      end

      def self.daru_vector?(x)
        defined?(Daru::Vector) && x.is_a?(Daru::Vector)
      end

      def self.narray_vector?(x)
        defined?(Numo::NArray) && x.is_a?(Numo::NArray) && x.ndim == 1
      end

      def self.nmatrix_vector?(x)
        defined?(NMatrix) && x.is_a?(NMatrix) && x.dim == 1
      end

      def self.numpy_vector?(x)
        defined?(Numpy::NDArray) && x.is_a?(Numpy::NDArray) && x.ndim == 1
      end

      def self.pandas_series?(x)
        defined?(Pandas::Series) && x.is_a?(Pandas::Series)
      end

      def initialize(data, columns: nil, index: nil)
        case data
        when Hash
          arrays = data.values
          columns ||= data.keys
        when Array
          case data[0]
          when Numeric, String, Time, Date
            arrays = [data]
          when Hash
            columns ||= data.map(&:keys).inject(&:|)
            arrays = columns.map { [] }
            data.each do |record|
              columns.each_with_index do |key, i|
                arrays[i] << record[key]
              end
            end
          when self.class.method(:array?)
            unsupported_data_format unless data.all?(&self.class.method(:array?))
            arrays = data.map(&:to_a).transpose
          else
            unsupported_data_format
          end
        else
          unsupported_data_format
        end

        unless arrays.empty?
          arrays, columns, index = check_data(arrays, columns, index)
        end

        @data = arrays.map.with_index {|a, i| [columns[i], a] }.to_h
        self.columns = columns unless columns.nil?
        self.index = index unless index.nil?
      end

      private def check_data(arrays, columns, index)
        # NOTE: After Ruby 2.7, we can write the following code by filter_map:
        #         indexes = Util.filter_map(arrays) {|ary| ary.index if ary.is_a?(Charty::Vector) }
        indexes = []
        arrays.each do |array|
          index = case array
                  when Charty::Vector
                    array.index
                  when ->(x) { defined?(Daru) && x.is_a?(Daru::Vector) }
                    Charty::DaruIndex.new(array.index)
                  when ->(x) { defined?(Pandas) && x.is_a?(Pandas::Series) }
                    Charty::PandasIndex.new(array.index)
                  else
                    if index.nil?
                      RangeIndex.new(0 ... array.size)
                    else
                      check_and_convert_index(index, :index, array.size)
                    end
                  end
          indexes << index
        end
        index = union_indexes(*indexes)

        arrays = arrays.map do |array|
          case array
          when Charty::Vector
            array.data
          when Hash
            raise NotImplementedError
          when self.class.method(:array?)
            array
          else
            Array.try_convert(array)
          end
        end

        columns = generate_column_names(arrays.length, columns)

        return arrays, columns, index
      end

      private def union_indexes(*indexes)
        result = nil
        while result.nil? && indexes.length > 0
          result = indexes.shift
        end
        indexes.each do |index|
          next if index.nil?
          result = result.union(index)
        end
        result
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

      def compare_data_equality(other)
        case other
        when DaruAdapter, PandasDataFrameAdapter
          other.compare_data_equality(self)
        else
          super
        end
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          case column
          when Symbol
            sym_key = column
            str_key = column.to_s
          else
            str_key = String.try_convert(column)
            sym_key = str_key.to_sym
          end

          column_data = if @data.key?(sym_key)
                          @data[sym_key]
                        else
                          @data[str_key]
                        end
          Vector.new(column_data, index: index, name: column)
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

      def reset_index
        index_name = index.name || :index
        Charty::Table.new({ index_name => index.to_a }.merge(data))
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
