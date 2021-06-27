require "delegate"

module Charty
  module TableAdapters
    class DaruAdapter < BaseAdapter
      TableAdapters.register(:daru, self)

      extend Forwardable
      include Enumerable

      def self.supported?(data)
        defined?(Daru::DataFrame) && data.is_a?(Daru::DataFrame)
      end

      def initialize(data, columns: nil, index: nil)
        @data = check_type(Daru::DataFrame, data, :data)

        self.columns = columns unless columns.nil?
        self.index = index unless index.nil?
      end

      attr_reader :data

      def_delegator :data, :size, :length

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

      def compare_data_equality(other)
        case other
        when DaruAdapter
          data == other.data
        else
          super
        end
      end

      def [](row, column)
        if row
          @data[column][row]
        else
          column_data = if @data.has_vector?(column)
                          @data[column]
                        else
                          case column
                          when String
                            @data[column.to_sym]
                          else
                            @data[column.to_s]
                          end
                        end
          Vector.new(column_data)
        end
      end

      private def check_type(type, data, name)
        return data if data.is_a?(type)
        raise TypeError, "#{name} must be a #{type}"
      end
    end
  end
end
