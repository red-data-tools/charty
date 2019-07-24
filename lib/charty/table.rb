require 'forwardable'

module Charty
  class ColumnAccessor
    def initialize(adapter)
      @adapter = adapter
    end

    def [](i)
      @adapter.column(i)
    end
  end

  class Table
    extend Forwardable

    def initialize(data, **kwargs)
      adapter_maker = TableAdapters.find_adapter_maker(data)
      @adapter = adapter_maker.make(data, **kwargs)
    end

    attr_reader :adapter

    def_delegator :@adapter, :columns

    def arrays
      @column_accessor ||= ColumnAccessor.new(@adapter)
    end

    def [](*args)
      case args.length
      when 1
        arrays[args[0]]
      when 2
        i, j = args
        @adapter[i, j]
      end
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
  end
end
