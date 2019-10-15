module Charty
  module TableAdapters
    class DaruAdapter
      TableAdapters.register(:daru, self)

      include Enumerable

      def self.supported?(data)
        defined?(Daru::DataFrame) && data.is_a?(Daru::DataFrame)
      end

      def initialize(data)
        @data = check_type(Daru::DataFrame, data, :data)
      end

      attr_reader :data

      def column_names
        @data.vectors.to_a
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          @data[column]
        end
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
