module Charty
  module TableAdapters
    @adapters = {}

    def self.register(name, adapter_class)
      @adapters[name] = adapter_class
    end

    def self.find_adapter_class(data)
      @adapters.each_value do |adapter_class|
        return adapter_class if adapter_class.supported?(data)
      end
      raise ArgumentError, "Unsupported data class: #{data.class}"
    end
  end
end

require_relative 'table_adapters/base_adapter'
require_relative 'table_adapters/hash_adapter'
require_relative 'table_adapters/narray_adapter'
require_relative 'table_adapters/datasets_adapter'
require_relative 'table_adapters/daru_adapter'
require_relative 'table_adapters/active_record_adapter'
require_relative 'table_adapters/nmatrix_adapter'
require_relative 'table_adapters/pandas_adapter'
