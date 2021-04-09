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
          when Numeric, String, Time, Date, DateTime, true, false
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
    end
  end
end
