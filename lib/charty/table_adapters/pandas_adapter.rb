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

      def column?(name)
        data.__contains__(name)
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
          case column
          when Array
            Table.new(@data[column])
          else
            Vector.new(@data[column])
          end
        end
      end

      def []=(key, values)
        all_slice = PyCall::Slice.new(nil)
        case values
        when Charty::Vector
          case values.adapter
          when Charty::VectorAdapters::PandasSeriesAdapter
            @data.loc[all_slice, key] = values.adapter.data
          else
            @data.loc[all_slice, key] = values.to_a
          end
        else
          orig_values = values
          values = Array.try_convert(values)
          if values.nil?
            raise ArgumentError, "`values` must be convertible to Array"
          end
          @data.loc[all_slice, key] = values
        end
        return values
      end

      def drop_na
        Charty::Table.new(@data.dropna)
      end

      def sort_values(by, na_position: :last)
        Charty::Table.new(@data.sort_values(by, na_position: na_position, kind: :mergesort))
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end

      def group_by(_table, grouper, sort, drop_na)
        GroupBy.new(@data.groupby(by: grouper, sort: sort, dropna: drop_na))
      end

      def reset_index
        Charty::Table.new(data.reset_index)
      end

      def melt(id_vars: nil, value_vars: nil, var_name: nil, value_name: :value)
        id_vars = check_melt_vars(id_vars, :id_vars) { nil }
        value_vars = check_melt_vars(value_vars, :value_vars) { nil }

        Charty::Table.new(data.melt(id_vars: id_vars, value_vars: value_vars,
                                    var_name: var_name, value_name: value_name,
                                    ignore_index: true))
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

        def group_keys
          each_group_key.to_a
        end

        # TODO: test
        def each_group_key
          return enum_for(__method__) unless block_given?

          if PyCall.respond_to?(:iterable)
            PyCall.iterable(@groupby).each do |key, index|
              if key.class == PyCall.builtins.tuple
                key = key.to_a
              end
              yield key
            end
          else # TODO: Remove this clause after the new PyCall will be released
            iter = @groupby.__iter__()
            while true
              begin
                key, sub_data = iter.__next__
                if key.class == PyCall.builtins.tuple
                  key = key.to_a
                end
                yield key
              rescue PyCall::PyError => error
                if error.type == PyCall.builtins.StopIteration
                  break
                else
                  raise error
                end
              end
            end
          end
        end

        # TODO: test
        def each_group
          return enum_for(__method__) unless block_given?

          each_group_key do |key|
            yield(Array(key), self[key])
          end
        end

        def apply(*args, &block)
          res = @groupby.apply(->(data) {
            res = block.call(Charty::Table.new(data), *args)
            Pandas::Series.new(data: res)
          })
          Charty::Table.new(res)
        end

        def [](key)
          key = case key
                when PyCall::Tuple
                  key
                else
                  PyCall::Tuple.new(*key.to_a)
                end
          Charty::Table.new(@groupby.get_group(key))
        end
      end
    end
  end
end
