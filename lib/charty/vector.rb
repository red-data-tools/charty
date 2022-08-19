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

    def initialize(data, index: nil, name: nil)
      adapter_class = VectorAdapters.find_adapter_class(data)
      @adapter = adapter_class.new(data)
      self.index = index unless index.nil?
      self.name = name unless name.nil?
    end

    attr_reader :adapter

    def_delegators :adapter, :data
    def_delegators :adapter, :index, :index=
    def_delegators :adapter, :==, :[], :[]=

    def_delegators :adapter, :length
    def_delegators :adapter, :name, :name=

    alias size length

    def_delegators :adapter, :iloc
    def_delegators :adapter, :to_a
    def_delegators :adapter, :each
    def_delegators :adapter, :empty?

    def_delegators :adapter, :boolean?, :numeric?, :categorical?
    def_delegators :adapter, :categories
    def_delegators :adapter, :unique_values
    def_delegators :adapter, :group_by
    def_delegators :adapter, :drop_na
    def_delegators :adapter, :values_at

    def_delegators :adapter, :eq, :notnull

    alias completecases notnull

    def_delegators :adapter, :mean, :stdev, :percentile

    def_delegators :adapter, :scale, :scale_inverse

    def scale(method)
      case method
      when :linear
        self
      when :log
        adapter.log_scale(method)
      else
        raise ArgumentError,
              "Invalid scaling method: %p" % method
      end
    end

    def scale_inverse(method)
      case method
      when :linear
        self
      when :log
        adapter.inverse_log_scale(method)
      else
        raise ArgumentError,
              "Invalid scaling method: %p" % method
      end
    end

    # TODO: write test
    def categorical_order(order=nil)
      if order.nil?
        case
        when categorical?
          order = categories
        else
          order = unique_values.compact
          if numeric?
            order.sort_by! {|x| Util.missing?(x) ? Float::INFINITY : x }
          end
        end
        order.compact!
      end
      order
    end
  end
end
