require "delegate"

module Charty
  module TableAdapters
    class DaruAdapter
      TableAdapters.register(:daru, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(Daru::DataFrame) && data.is_a?(Daru::DataFrame)
      end

      def initialize(data)
        @data = check_type(Daru::DataFrame, data, :data)
      end

      attr_reader :data

      def index
        DaruIndex.new(data.index)
      end

      def_delegator :data, :index=

      def columns
        DaruIndex.new(data.vectors)
      end

      def columns=(values)
        data.vectors = Daru::Index.coerce(values)
      end

      def column_names
        @data.vectors.to_a
      end

      def ==(other)
        return true if equal?(other)

        case other
        when BaseAdapter
          case other
          when DaruAdapter
            return false if index != other.index
            data == other.data
          when HashAdapter
            return false unless other.index == self.index  # Use Charty::Index#==
            return false unless column_names == other.column_names

            data.vectors.all? do |name|
              data[name].to_a == other.data[name]
            end
          else
            raise NotImplementedError
          end
        else
          false
        end
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
