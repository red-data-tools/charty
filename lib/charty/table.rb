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
    end

    attr_reader :adapter

    def_delegators :adapter, :length, :column_length

    def_delegators :adapter, :columns, :columns=
    def_delegators :adapter, :index, :index=

    def_delegator :@adapter, :column_names
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

    def [](*args)
      n_args = args.length
      case n_args
      when 1
        row = nil
        column = args[0]
        @adapter[row, column]
      when 2
        row = args[0]
        column = args[1]
        @adapter[row, column]
      else
        message = "wrong number of arguments (given #{n_args}, expected 1..2)"
        raise ArgumentError, message
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
