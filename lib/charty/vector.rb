require "forwardable"

module Charty
  class Vector
    extend Forwardable
    include Enumerable

    def self.try_convert(obj)
      case obj
      when self
        obj
      else
        if VectorAdapters.find_adapter_class(obj, exception: false)
          new(obj)
        end
      end
    end

    def initialize(data, name: nil)
      adapter_class = VectorAdapters.find_adapter_class(data)
      @adapter = adapter_class.new(data)
      self.name = name unless name.nil?
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

    def_delegators :adapter, :categorical?, :numeric?
    def_delegators :adapter, :categories
    def_delegators :adapter, :unique_values
    def_delegators :adapter, :group_by
    def_delegators :adapter, :drop_na
    def_delegators :adapter, :values_at
  end
end
