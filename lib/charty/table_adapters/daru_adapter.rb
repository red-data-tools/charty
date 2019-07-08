require 'daru'

module Charty
  module TableAdapters
    class DaruAdapter
      extend Forwardable
      include Enumerable

      def self.make(data)
        self.new(data)
      end

      def initialize(data)
        @data = check_type(Daru::DataFrame, data, :data)
      end

      def columns
        @data.vectors.to_a
      end

      def [](i, j)
        @data[j][i]
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
