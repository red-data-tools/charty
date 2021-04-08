require "forwardable"

module Charty
  module VectorAdapters
    class UnsupportedVectorData < StandardError; end

    @adapters = {}

    def self.register(name, adapter_class)
      @adapters[name] = adapter_class
    end

    def self.find_adapter_class(data)
      @adapters.each_value do |adapter_class|
        return adapter_class if adapter_class.supported?(data)
      end
      raise UnsupportedVectorData, "Unsupported vector data (#{data.class})"
    end

    class BaseAdapter
      extend Forwardable
      include Enumerable

      private def check_data(data)
        return data if self.class.supported?(data)
        raise UnsupportedVectorData, "Unsupported vector data (#{data.class})"
      end
    end
  end
end

require_relative "vector_adapters/pandas_adapter"
