module Charty
  module VectorAdapters
    class DaruVectorAdapter < BaseAdapter
      VectorAdapters.register(:daru_vector, self)

      def self.supported?(data)
        defined?(Daru::Vector) && data.is_a?(Daru::Vector)
      end

      def initialize(data)
        @data = check_data(data)
      end

      def_delegator :data, :size, :length

      def index
        DaruIndex.new(data.index)
      end

      def index=(new_index)
        case new_index
        when DaruIndex
          data.index = new_index.values
        when Index
          data.index = new_index.to_a
        else
          data.index = new_index
        end
      end

      def_delegators :data, :name, :name=

      def compare_data_equality(other)
        case other
        when DaruVectorAdapter
          data == other.data
        when ArrayAdapter
          data.to_a == other.data
        when NArrayAdapter, NMatrixAdapter, NumpyAdapter, PandasSeriesAdapter
          other.compare_data_equality(self)
        else
          data == other.data.to_a
        end
      end

      def [](key)
        case key
        when Charty::Vector
          where(key)
        else
          data[key]
        end
      end

      def_delegators :data, :[]=, :to_a

      def values_at(*indices)
        indices.map {|i| data.at(i) }
      end

      def where(mask)
        masked_data, masked_index = where_in_array(mask)
        Charty::Vector.new(Daru::Vector.new(masked_data, index: masked_index), name: name)
      end

      def where_in_array(mask)
        mask = check_mask_vector(mask)
        masked_data = []
        masked_index = []
        mask.each_with_index do |f, i|
          case f
          when true, 1
            masked_data << data[i]
            masked_index << data.index.key(i)
          end
        end
        return masked_data, masked_index
      end

      def first_nonnil
        data.drop_while(&:nil?).first
      end

      def boolean?
        case
        when numeric?, categorical?
          false
        else
          case first_nonnil
          when true, false
            true
          else
            false
          end
        end
      end

      def_delegators :data, :numeric?
      def_delegator :data, :category?, :categorical?

      def categories
        data.categories.compact if categorical?
      end

      def unique_values
        data.uniq.to_a
      end

      def group_by(grouper)
        case grouper
        when Daru::Vector
          if grouper.category?
            # TODO: A categorical Daru::Vector cannot perform group_by well
            grouper = Daru::Vector.new(grouper.to_a)
          end
          groups = grouper.group_by.groups
          groups.map { |g, indices|
            [g.first, Charty::Vector.new(data[*indices])]
          }.to_h
        when Charty::Vector
          case grouper.data
          when Daru::Vector
            return group_by(grouper.data)
          else
            return group_by(Daru::Vector.new(grouper.to_a))
          end
        else
          return group_by(Charty::Vector.new(grouper))
        end
      end

      def drop_na
        values = data.reject {|x| Util.missing?(x) }
        Charty::Vector.new(Daru::Vector.new(values))
      end

      def eq(val)
        Charty::Vector.new(data.eq(val).to_a,
                           index: data.index.to_a,
                           name: name)
      end

      def notnull
        notnull_data = data.map {|x| ! Util.missing?(x) }
        Charty::Vector.new(notnull_data, index: data.index.to_a, name: name)
      end

      def_delegator :data, :mean

      def stdev(population: false)
        if population
          data.standard_deviation_sample
        else
          data.standard_deviation_population
        end
      end

      def percentile(q)
        a = data.reject_values(*Daru::MISSING_VALUES).to_a
        Statistics.percentile(a, q)
      end
    end
  end
end
