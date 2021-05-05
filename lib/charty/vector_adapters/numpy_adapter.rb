module Charty
  module VectorAdapters
    class NumpyAdapter < BaseAdapter
      VectorAdapters.register(:numpy, self)

      def self.supported?(data)
        return false unless defined?(Numpy::NDArray)
        case data
        when Numpy::NDArray
          true
        else
          false
        end
      end

      def initialize(data)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      attr_reader :data

      def_delegator :data, :size, :length

      include NameSupport
      include IndexSupport

      def where(mask)
        mask = check_mask_vector(mask)
        case mask.data
        when Numpy::NDArray,
             ->(x) { defined?(Pandas::Series) && x.is_a?(Pandas::Series) }
          mask_data = Numpy.asarray(mask.data, dtype: :bool)
          masked_data = data[mask_data]
          masked_index = mask_data.nonzero()[0].to_a.map {|i| index[i] }
        else
          masked_data, masked_index = where_in_array(mask)
          masked_data = Numpy.asarray(masked_data, dtype: data.dtype)
        end
        Charty::Vector.new(masked_data, index: masked_index, name: name)
      end

      def each
        return enum_for(__method__) unless block_given?

        i, n = 0, data.size
        while i < n
          yield data[i]
          i += 1
        end
      end

      def empty?
        data.size == 0
      end

      def boolean?
        builtins = PyCall.builtins
        case
        when builtins.issubclass(data.dtype.type, Numpy.bool_)
          true
        when builtins.issubclass(data.dtype.type, Numpy.object_)
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
        # TODO: Handle object array
        PyCall.builtins.issubclass(data.dtype.type, PyCall.tuple([Numpy.number, Numpy.bool_]))
      end

      def categorical?
        false
      end

      def categories
        nil
      end

      def unique_values
        Numpy.unique(data).to_a
      end

      def group_by(grouper)
        case grouper
        when Numpy::NDArray,
             ->(x) { defined?(Pandas::Series) && x.is_a?(Pandas::Series) }
          # Nothing todo
        when Charty::Vector
          case grouper.data
          when Numpy::NDArray
            grouper = grouper.data
          else
            grouper = Numpy.asarray(grouper.to_a)
          end
        else
          grouper = Numpy.asarray(Array.try_convert(grouper))
        end

        group_keys = Numpy.unique(grouper).to_a
        group_keys.map { |g|
          [g, Charty::Vector.new(data[grouper == g])]
        }.to_h
      end

      def drop_na
        where_is_na = if numeric?
                        Numpy.isnan(data)
                      else
                        (data == nil)
                      end
        Charty::Vector.new(data[Numpy.logical_not(where_is_na)])
      end

      def eq(val)
        Charty::Vector.new((data == val),
                           index: index,
                           name: name)
      end

      def mean
        Numpy.mean(data)
      end

      def stdev(population: false)
        Numpy.std(data, ddof: population ? 0 : 1)
      end
    end
  end
end
