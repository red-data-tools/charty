module Charty
  module TableAdapters
    class DaruAdapter
      include Enumerable

      def self.supported?(data)
        defined?(Daru::DataFrame) && data.is_a?(Daru::DataFrame)
      end

      def initialize(data)
        @data = check_type(Daru::DataFrame, data, :data)
      end

      def columns
        @data.vectors.to_a
      end

      def column(i)
        @data[i]
      end

      def [](i, j)
        column(j)[i]
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end

    register(:daru, DaruAdapter)
  end
end
