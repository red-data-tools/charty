module Charty
  module VectorAdapters
    class PandasSeriesAdapter < BaseAdapter
      VectorAdapters.register(:pandas_series, self)

      def self.supported?(data)
        return false unless defined?(Pandas::Series)
        case data
        when Pandas::Series
          true
        else
          false
        end
      end

      def initialize(data)
        @data = check_data(data)
      end

      attr_reader :data

      def_delegator :data, :size, :length

      def index
        PandasIndex.new(data.index)
      end

      def index=(new_index)
        case new_index
        when PandasIndex
          data.index = new_index.values
        when Index
          data.index = new_index.to_a
        else
          data.index = new_index
        end
      end

      def_delegators :data, :name, :name=

      def [](key)
        case key
        when Charty::Vector
          where(key)
        else
          data[key]
        end
      end

      def_delegators :data, :[]=, :to_a

      def each
        return enum_for(__method__) unless block_given?

        i, n = 0, data.size
        while i < n
          yield data.iloc[i]
          i += 1
        end
      end

      def empty?
        data.size == 0
      end

      # TODO: Reconsider the return value type of values_at
      def values_at(*indices)
        data.take(indices).to_a
      end

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
          masked_data = Pandas::Series.new(masked_data, dtype: data.dtype)
        end
        Charty::Vector.new(masked_data, index: masked_index, name: name)
      end

      def where_in_array(mask)
        mask = check_mask_vector(mask)
        masked_data = []
        masked_index = []
        mask.each_with_index do |f, i|
          case f
          when true, 1
            masked_data << data.iloc[i]
            masked_index << index[i]
          end
        end
        return masked_data, masked_index
      end

      def boolean?
        case
        when Pandas.api.types.is_bool_dtype(data.dtype)
          true
        when Pandas.api.types.is_object_dtype(data.dtype)
          data.isin([nil, false, true]).all()
        else
          false
        end
      end

      def numeric?
        Pandas.api.types.is_numeric_dtype(data.dtype)
      end

      def categorical?
        Pandas.api.types.is_categorical_dtype(data.dtype)
      end

      def categories
        data.cat.categories.to_a if categorical?
      end

      def unique_values
        data.unique.to_a
      end

      def group_by(grouper)
        case grouper
        when Pandas::Series
          group_keys = grouper.unique.to_a
          groups = data.groupby(grouper)
          group_keys.map {|g|
            [g, Charty::Vector.new(groups.get_group(g))]
          }.to_h
        when Charty::Vector
          case grouper.adapter
          when self.class
            group_by(grouper.data)
          else
            grouper = Pandas::Series.new(grouper.to_a)
            group_by(grouper)
          end
        else
          grouper = Pandas::Series.new(Array(grouper))
          group_by(grouper)
        end
      end

      def drop_na
        Charty::Vector.new(data.dropna)
      end

      def eq(val)
        Charty::Vector.new((data == val),
                           index: index,
                           name: name)
      end

      def notnull
        Charty::Vector.new(data.notnull, index: index, name: name)
      end

      def mean
        data.mean()
      end

      def stdev(population: false)
        data.std(ddof: population ? 0 : 1)
      end

      def percentile(q)
        q = q.map {|x| x / 100.0 }
        data.quantile(q)
      end
    end
  end
end
