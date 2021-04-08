module Charty
  module TableAdapters
    class PandasDataFrameAdapter
      TableAdapters.register(:pandas_data_frame, self)

      include Enumerable

      def self.supported?(data)
        defined?(Pandas::DataFrame) && data.is_a?(Pandas::DataFrame)
      end

      def initialize(data)
        @data = check_type(Pandas::DataFrame, data, :data)
      end

      attr_reader :data

      def column_names
        @data.columns.to_a
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          Vector.new(@data[column])
        end
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
