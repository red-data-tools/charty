
module Charty
  class Table
    def initialize(table)
      @table = table
    end

    attr_reader :table

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
