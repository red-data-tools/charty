module Charty
  module TableAdapters
    @adapters = {}

    def self.register(name, adapter)
      @adapters[name] = adapter
    end

    def self.lookup_adapter_maker(data)
      @adapters.each_value do |adapter|
        return adapter if adapter.supported?(data)
      end
      raise ArgumentError, "Unsupported data class: #{data.class}"
    end
  end
end

require_relative 'table_adapters/hash_adapter'
require_relative 'table_adapters/narray_adapter'
require_relative 'table_adapters/datasets_adapter'
require_relative 'table_adapters/daru_adapter'
require_relative 'table_adapters/nmatrix_adapter'
