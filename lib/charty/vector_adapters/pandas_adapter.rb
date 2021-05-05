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
      def_delegators :data, :index, :index=
      def_delegators :data, :name, :name=
      def_delegators :data, :[], :[]=
      def_delegators :data, :to_a

      def empty?
        data.size == 0
      end

      # TODO: Reconsider the return value type of values_at
      def values_at(*indices)
        data.take(indices).to_a
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
