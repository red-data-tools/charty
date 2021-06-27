require 'forwardable'

module Charty
  class ColumnAccessor
    def initialize(adapter)
      @adapter = adapter
    end

    def [](column_name)
      @adapter[nil, column_name]
    end
  end

  class Table
    extend Forwardable

    def initialize(data, **kwargs)
      adapter_class = TableAdapters.find_adapter_class(data)
      if kwargs.empty?
        @adapter = adapter_class.new(data)
      else
        @adapter = adapter_class.new(data, **kwargs)
      end

      @column_cache = {}
    end

    attr_reader :adapter

    def_delegators :adapter, :length, :column_length

    def_delegators :adapter, :columns, :columns=
    def_delegators :adapter, :index, :index=

    def_delegators :@adapter, :column_names, :column?

    def_delegator :@adapter, :data, :raw_data

    def ==(other)
      return true if equal?(other)

      case other
      when Charty::Table
        adapter == other.adapter
      else
        super
      end
    end

    def empty?
      length == 0
    end

    def [](key)
      case key
      when Array
        @adapter[nil, key]
      else
        key = case key
              when Symbol
                key
              else
                String.try_convert(key).to_sym
              end
        if @column_cache.key?(key)
          @column_cache[key]
        else
          @column_cache[key] = @adapter[nil, key]
        end
      end
    end

    def []=(key, values)
      case key
      when Array
        raise ArgumentError,
              "Substituting multiple keys is not supported"
      when Symbol
        # do nothing
      else
        key = key.to_str.to_sym
      end
      @adapter[key] = values
    end

    def group_by(grouper, sort: true, drop_na: true)
      adapter.group_by(self, grouper, sort, drop_na)
    end

    def to_a(x=nil, y=nil, z=nil)
      case
      when defined?(Daru::DataFrame) && table.kind_of?(Daru::DataFrame)
        table.map(&:to_a)
      when defined?(Numo::NArray) && table.kind_of?(Numo::NArray)
        table.to_a
      when defined?(NMatrix) && table.kind_of?(NMatrix)
        table.to_a
      when defined?(ActiveRecord::Relation) && table.kind_of?(ActiveRecord::Relation)
        if z && x && y
          [table.pluck(x), table.pluck(y), table.pluck(z)]
        elsif x && y
          [table.pluck(x), table.pluck(y)]
        else
          raise ArgumentError, "column_names is required to convert to_a from ActiveRecord::Relation"
        end
      when table.kind_of?(Array)
        table
      else
        raise ArgumentError, "unsupported object: #{table.inspect}"
      end
    end

    def each
      return to_enum(__method__) unless block_given?
      data = to_a
      i, n = 0, data.size
      while i < n
        yield data[i]
        i += 1
      end
    end

    def drop_na
      @adapter.drop_na || self
    end

    def_delegator :adapter, :sort_values

    def_delegator :adapter, :reset_index

    def_delegator :adapter, :melt

    class GroupByBase
    end

    class HashGroupBy < GroupByBase
      def initialize(table, grouper, sort, drop_na)
        @table = table
        @grouper = check_grouper(grouper)
        init_groups(sort, drop_na)
      end

      private def check_grouper(grouper)
        case grouper
        when Symbol, String, Array
          # TODO check column existence
          return grouper
        when Charty::Vector
          if @table.length != grouper.length
            raise ArgumentError,
                  "Wrong number of items in grouper array " +
                  "(%p for %p)" % [val.length, @table.length]
          end
          return grouper
        when ->(x) { x.respond_to?(:call) }
          raise NotImplementedError,
                "A callable grouper is unsupported"
        else
          raise ArgumentError,
                "Unable to recognize the value for `grouper`: %p" % val
        end
      end

      private def init_groups(sort, drop_na)
        case @grouper
        when Symbol, String
          column = @table[@grouper]
          @indices = (0 ... @table.length).group_by do |i|
            column.data[i]
          end
        when Array
          @indices = (0 ... @table.length).group_by { |i|
            @grouper.map {|j| @table[j].data[i] }
          }
        when Charty::Vector
          @indices = (0 ... @table.length).group_by do |i|
            @grouper.data[i]
          end
        end

        if drop_na
          case @grouper
          when Array
            @indices.reject! {|key, | key.any? {|k| Util.missing?(k) } }
          else
            @indices.reject! {|key, | Util.missing?(key) }
          end
        end

        if sort
          @indices = @indices.sort_by {|key, | key }.to_h
        end
      end

      def indices
        @indices.dup
      end

      def group_keys
        @indices.keys
      end

      def each_group_key(&block)
        @indices.each_key(&block)
      end

      def apply(*args, &block)
        Charty::Table.new(
          each_group.map { |_key, table|
            block.call(table, *args)
          },
          index: Charty::Index.new(@indices.keys, name: @grouper)
        )
      end

      def each_group
        return enum_for(__method__) unless block_given?

        @indices.each_key do |key|
          yield(key, self[key])
        end
      end

      def [](key)
        return nil unless @indices.key?(key)

        index = @indices[key]
        Charty::Table.new(
          @table.column_names.map {|col|
            [col, @table[col].values_at(*index)]
          }.to_h,
          index: index
        )
      end
    end
  end
end
