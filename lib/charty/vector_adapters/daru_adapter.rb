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
      def_delegators :data, :index, :index=
      def_delegators :data, :name, :name=
      def_delegators :data, :[], :[]=
      def_delegators :data, :to_a

      def values_at(*indices)
        indices.map {|i| data[i] }
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
        values = data.reject do |x|
          case
          when x.nil?,
               x.respond_to?(:nan?) && x.nan?
            true
          else
            false
          end
        end
        Charty::Vector.new(Daru::Vector.new(values))
      end

      def eq(val)
        Charty::Vector.new(data.eq(val).to_a,
                           index: index.to_a,
                           name: name)
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
        data.linear_percentile(q)
      end
    end
  end
end
