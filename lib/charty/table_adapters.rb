module Charty
  module TableAdapters
    def self.lookup_adapter_maker(data)
      if defined?(Datasets::Dataset) && data.kind_of?(Datasets::Dataset)
        require_relative 'table_adapters/datasets_adapter'
        return DatasetsAdapter
      end
    end
  end
end
