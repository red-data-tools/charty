module Charty
  class AdapterNotLoadedError < RuntimeError; end

  class PlotterAdapter
    def self.inherited(adapter_class)
      @adapters ||= []
      @adapters << adapter_class
    end

    def self.create(adapter_name)
      require "charty/#{adapter_name}"
      adapter = @adapters.find {|adapter| adapter::Name.to_s == adapter_name.to_s }
      raise AdapterNotLoadedError.new("Adapter for '#{adapter_name}' is not found.") unless adapter
      adapter.new
    end
  end
end
