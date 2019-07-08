module Charty
  module TableAdapters
    class HashAdapter
      extend Forwardable
      include Enumerable

      def self.make(data)
        new(data)
      end

      def initialize(data)
        @data = check_type(Hash, data, :data)
      end

      def_delegator :@data, :keys, :columns

      def [](i, j)
        @data[j][i]
      end

      def each
        i, n = 0, shape[0]
        while i < n
          record = @data.map {|k, v| v[i] }
          yield record
          i += 1
        end
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
