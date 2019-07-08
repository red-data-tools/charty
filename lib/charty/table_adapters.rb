module Charty
  module TableAdapters
    def self.lookup_adapter_maker(data)
      case data
      when Hash
        return HashAdapter
      else
        if defined?(Datasets::Dataset) && data.kind_of?(Datasets::Dataset)
          require_relative 'table_adapters/datasets_adapter'
          return DatasetsAdapter
        end
        if defined?(Daru::DataFrame) && data.kind_of?(Daru::DataFrame)
          require_relative 'table_adapters/daru_adapter'
          return DaruAdapter
        end
        raise ArgumentError, "Unsupported data class: #{data.class}"
      end
    end
  end
end

require_relative 'table_adapters/hash_adapter'
