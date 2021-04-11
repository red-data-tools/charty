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
    end
  end
end
