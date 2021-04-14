require "forwardable"

module Charty
  class Vector
    extend Forwardable
    include Enumerable

    def initialize(data)
      adapter_class = VectorAdapters.find_adapter_class(data)
      @adapter = adapter_class.new(data)
    end

    attr_reader :adapter

    def_delegators :adapter, :data
    def_delegators :adapter, :index, :index=
    def_delegators :adapter, :[], :[]=

    def_delegators :adapter, :length
    def_delegators :adapter, :name, :name=

    alias size length

    def_delegators :adapter, :to_a
    def_delegators :adapter, :each
  end
end
