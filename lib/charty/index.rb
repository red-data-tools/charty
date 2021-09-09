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

    def ==(other)
      case other
      when DaruIndex, PandasIndex
        return false if length != other.length
        to_a == other.to_a
      when Index
        return false if length != other.length
        return true if values == other.values
        to_a == other.to_a
      else
        super
      end
    end

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

    def union(other)
      case other
      when PandasIndex
        index = PandasIndex.try_convert(self)
        return index.union(other) if index
      end

      Index.new(to_a.union(other.to_a), name: name)
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
        raise IndexError, "index out of range (#{i} for 0 ... #{length})"
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

    def union(other)
      case other
      when RangeIndex
        return union(other.values)
      when Range
        if disjoint_range?(values, other)
          return Index.new(values.to_a.union(other.to_a))
        end
        new_beg = [values.begin, other.begin].min
        new_end = [values.end,   other.end  ].max
        new_range = if values.end < new_end
                      if other.exclude_end?
                        new_beg ... new_end
                      else
                        new_beg .. new_end
                      end
                    elsif other.end < new_end
                      if values.exclude_end?
                        new_beg ... new_end
                      else
                        new_beg .. new_end
                      end
                    else
                      if values.exclude_end? && other.exclude_end?
                        new_beg ... new_end
                      else
                        new_beg .. new_end
                      end
                    end
        RangeIndex.new(new_range)
      else
        super
      end
    end

    private def disjoint_range?(r1, r2)
      r1.end < r2.begin || r2.end < r1.begin
    end
  end

  class DaruIndex < Index
    def_delegators :values, :name, :name=

    def length
      size
    end

    def ==(other)
      case other
      when DaruIndex
        values == other.values
      else
        super
      end
    end
  end

  class PandasIndex < Index
    def self.try_convert(obj)
      case obj
      when PandasIndex
        obj
      when ->(x) { defined?(Pandas) && x.is_a?(Pandas::Index) }
        PandasIndex.new(obj)
      when RangeIndex, Range
        obj = obj.values if obj.is_a?(RangeIndex)
        stop = if obj.exclude_end?
                 obj.end
               else
                 obj.end + 1
               end
        PandasIndex.new(Pandas.RangeIndex.new(obj.begin, stop))
      when ->(x) { defined?(Enumerator::ArithmeticSequence) && x.is_a?(Enumerator::ArithmeticSequence) }
        stop = if obj.exclude_end?
                 obj.end
               else
                 obj.end + 1
               end
        PandasIndex.new(Pandas::RangeIndex.new(obj.begin, stop, obj.step))
      when Index, Array, DaruIndex, ->(x) { defined?(Daru) && x.is_a?(Daru::Index) }
        obj = obj.values if obj.is_a?(Index)
        PandasIndex.new(Pandas::Index.new(obj.to_a))
      else
        nil
      end
    end

    def_delegators :values, :name, :name=

    def length
      size
    end

    def ==(other)
      case other
      when PandasIndex
        Numpy.all(values == other.values)
      when Index
        return false if length != other.length
        Numpy.all(values == other.values.to_a)
      else
        super
      end
    end

    def each(&block)
      return enum_for(__method__) unless block_given?

      i, n = 0, length
      while i < n
        yield self[i]
        i += 1
      end
    end

    def loc(key)
      case values
      when Pandas::Index
        values.get_loc(key)
      else
        super
      end
    end

    def union(other)
      other = PandasIndex.try_convert(other)
      # NOTE: Using `sort=False` in pandas.Index#union does not produce pandas.RangeIndex.
      # TODO: Reconsider to use `sort=True` here.
      PandasIndex.new(values.union(other.values, sort: false))
    end

    private def arithmetic_sequence?(x)
      defined?(Enumerator::ArithmeticSequence) && x.is_a?(Enumerator::ArithmeticSequence)
    end
  end
end
