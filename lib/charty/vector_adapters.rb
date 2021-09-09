require "forwardable"

module Charty
  module VectorAdapters
    class UnsupportedVectorData < StandardError; end

    @adapters = {}

    def self.register(name, adapter_class)
      @adapters[name] = adapter_class
    end

    def self.find_adapter_class(data, exception: true)
      @adapters.each_value do |adapter_class|
        return adapter_class if adapter_class.supported?(data)
      end
      if exception
        raise UnsupportedVectorData, "Unsupported vector data (#{data.class})"
      end
    end

    class BaseAdapter
      extend Forwardable
      include Enumerable

      def self.adapter_name
        name[/:?(\w+)Adapter\z/, 1]
      end

      private def check_data(data)
        return data if self.class.supported?(data)
        raise UnsupportedVectorData, "Unsupported vector data (#{data.class})"
      end

      attr_reader :data

      def_delegators :data, :length, :size

      def ==(other)
        case other.adapter
        when BaseAdapter
          return false if other.index != index
          if respond_to?(:compare_data_equality)
            compare_data_equality(other.adapter)
          elsif other.adapter.respond_to?(:compare_data_equality)
            other.adapter.compare_data_equality(self)
          else
            case other.adapter
            when self.class
              data == other.data
            else
              false
            end
          end
        else
          super
        end
      end

      def_delegators :data, :[], :[]=
      def_delegators :data, :each, :to_a, :empty?

      # Take values at the given positional indices (without indexing)
      def values_at(*indices)
        indices.map {|i| data[i] }
      end

      def where_in_array(mask)
        mask = check_mask_vector(mask)
        masked_data = []
        masked_index = []
        mask.each_with_index do |f, i|
          case f
          when true, 1
            masked_data << data[i]
            masked_index << index[i]
          end
        end
        return masked_data, masked_index
      end

      private def check_mask_vector(mask)
        # ensure mask is boolean vector
        case mask
        when Charty::Vector
          unless mask.boolean?
            raise ArgumentError, "Unable to lookup items by a nonboolean vector"
          end
          mask
        else
          Charty::Vector.new(mask)
        end
      end

      def mean
        Statistics.mean(data)
      end

      def stdev(population: false)
        Statistics.stdev(data, population: population)
      end

      def percentile(q)
        Statistics.percentile(data, q)
      end

      def log_scale(method)
        Charty::Vector.new(
          self.map {|x| Math.log10(x) },
          index: index,
          name: name
        )
      end

      def inverse_log_scale(method)
        Charty::Vector.new(
          self.map {|x| 10.0 ** x },
          index: index,
          name: name
        )
      end
    end

    module NameSupport
      attr_reader :name

      def name=(value)
        @name = check_name(value)
      end

      private def check_name(value)
        value = String.try_convert(value) || value
        case value
        when String, Symbol
          value
        else
          raise ArgumentError,
                "name must be a String or a Symbol (#{value.class} is given)"
        end
      end
    end

    module IndexSupport
      attr_reader :index

      def [](key)
        case key
        when Charty::Vector
          where(key)
        else
          super(key_to_loc(key))
        end
      end

      def []=(key, val)
        super(key_to_loc(key), val)
      end

      private def key_to_loc(key)
        loc = self.index.loc(key)
        if loc.nil?
          if key.respond_to?(:to_int)
            loc = key.to_int
          else
            raise KeyError.new("key not found: %p" % key,
                               receiver: __method__, key: key)
          end
        end
        loc
      end

      def index=(values)
        @index = check_and_convert_index(values, :index, length)
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

require_relative "vector_adapters/array_adapter"
require_relative "vector_adapters/arrow_adapter"
require_relative "vector_adapters/daru_adapter"
require_relative "vector_adapters/narray_adapter"
require_relative "vector_adapters/nmatrix_adapter"
require_relative "vector_adapters/numpy_adapter"
require_relative "vector_adapters/pandas_adapter"
require_relative "vector_adapters/vector_adapter"
