require "date"

module Charty
  module VectorAdapters
    class ArrayAdapter < BaseAdapter
      VectorAdapters.register(:array, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        case data
        when Array
          case data[0]
          when Numeric, String, Time, Date, DateTime, true, false, nil
            true
          else
            false
          end
        else
          false
        end
      end

      def initialize(data, index: nil)
        @data = check_data(data)
        self.index = index || RangeIndex.new(0 ... length)
      end

      include NameSupport
      include IndexSupport

      # TODO: Reconsider the return value type of values_at
      def_delegators :data, :values_at

      def where(mask)
        masked_data, masked_index = where_in_array(mask)
        Charty::Vector.new(masked_data, index: masked_index, name: name)
      end

      def first_nonnil
        data.drop_while(&:nil?).first
      end

      def boolean?
        case first_nonnil
        when true, false
          true
        else
          false
        end
      end

      def numeric?
        case first_nonnil
        when Numeric
          true
        else
          false
        end
      end

      def categorical?
        false
      end

      def categories
        nil
      end

      def_delegator :data, :uniq, :unique_values

      def group_by(grouper)
        groups = data.each_index.group_by {|i| grouper[i] }
        groups.map { |g, vals|
          vals.collect! {|i| self[i] }
          [g, Charty::Vector.new(vals)]
        }.to_h
      end

      def drop_na
        if numeric?
          Charty::Vector.new(data.reject { |x|
            case x
            when Float
              x.nan?
            else
              x.nil?
            end
          })
        else
          Charty::Vector.new(data.compact)
        end
      end

      def eq(val)
        Charty::Vector.new(data.map {|x| x == val },
                           index: index,
                           name: name)
      end
    end
  end
end
