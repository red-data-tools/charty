module Charty
  module VectorAdapters
    class NArrayAdapter < BaseAdapter
      VectorAdapters.register(:narray, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(Numo::NArray) && data.is_a?(Numo::NArray)
      end

      def initialize(data)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      include NameSupport
      include IndexSupport

      # TODO: Reconsider the return value type of values_at
      def values_at(*indices)
        data[indices].to_a
      end

      def where(mask)
        mask = check_mask_vector(mask)
        case mask.data
        when Numo::Bit
          bits = mask.data
          masked_data = data[bits]
          masked_index = bits.where.map {|i| index[i] }.to_a
        else
          masked_data, masked_index = where_in_array(mask)
          masked_data = data.class[*masked_data]
        end
        Charty::Vector.new(masked_data, index: masked_index, name: name)
      end

      def boolean?
        case data
        when Numo::Bit
          true
        when Numo::RObject
          i, n = 0, data.size
          while i < n
            case data[i]
            when nil, true, false
              # do nothing
            else
              return false
            end
            i += 1
          end
          true
        else
          false
        end
      end

      def numeric?
        case data
        when Numo::Bit,
             Numo::RObject
          false
        else
          true
        end
      end

      def categorical?
        false
      end

      def categories
        nil
      end

      def unique_values
        existence = {}
        i, n = 0, data.size
        unique = []
        while i < n
          x = data[i]
          unless existence[x]
            unique << x
            existence[x] = true
          end
          i += 1
        end
        unique
      end

      def group_by(grouper)
        case grouper
        when Charty::Vector
          # nothing to do
        else
          grouper = Charty::Vector.new(grouper)
        end

        group_keys = grouper.unique_values

        case grouper.data
        when Numo::NArray
          grouper = grouper.data
        else
          grouper = Numo::NArray[*grouper.to_a]
        end

        group_keys.map { |g|
          [g, Charty::Vector.new(data[grouper.eq(g)])]
        }.to_h
      end

      def drop_na
        case data
        when Numo::DFloat, Numo::SFloat, Numo::DComplex, Numo::SComplex
          Charty::Vector.new(data[~data.isnan])
        when Numo::RObject
          where_is_nan = data.isnan
          values = []
          i, n = 0, data.size
          while i < n
            x = data[i]
            unless x.nil? || where_is_nan[i] == 1
              values << x
            end
            i += 1
          end
          Charty::Vector.new(Numo::RObject[*values])
        else
          self
        end
      end

      def eq(val)
        Charty::Vector.new(data.eq(val),
                           index: index,
                           name: name)
      end

      def notnull
        case data
        when Numo::RObject
          i, n = 0, length
          notnull_data = Numo::Bit.zeros(n)
          while i < n
            notnull_data[i] = ! missing_value?(data[i])
            i += 1
          end
        when ->(x) { x.respond_to?(:isnan) }
          notnull_data = ~data.isnan
        else
          notnull_data = Numo::Bit.ones(length)
        end
        Charty::Vector.new(notnull_data, index: index, name: name)
      end

      def mean
        data.mean(nan: true)
      end

      def stdev(population: false)
        s = data.stddev(nan: true)
        if population
          # Numo::NArray does not support population standard deviation
          n = data.isnan.sum
          s * (n - 1) / n
        else
          s
        end
      end
    end
  end
end
