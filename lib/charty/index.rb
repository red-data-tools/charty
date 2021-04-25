require "forwardable"

module Charty
  class Index
    extend Forwardable
    include Enumerable

    def initialize(values, name: nil)
      @values = values
      @name = name
    end

    attr_reader :values
    attr_accessor :name

    def_delegators :values, :length, :size, :each, :to_a

    def [](i)
      case i
      when 0 ... length
        values[i]
      else
        raise IndexError, "index out of range"
      end
    end

    def loc(key)
      values.index(key)
    end
  end

  class RangeIndex < Index
    def initialize(values, name: nil)
      if values.is_a?(Range) && values.begin.is_a?(Integer) && values.end.is_a?(Integer)
        super
      else
        raise ArgumentError, "values must be an integer range"
      end
    end

    def length
      size
    end

    def [](i)
      case i
      when 0 ... length
        values.begin + i
      else
        raise IndexError, "index out of range"
      end
    end

    def loc(key)
      case key
      when Integer
        if values.cover?(key)
          return key - values.begin
        end
      end
    end
  end
end
