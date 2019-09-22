module Charty
  class BackendNotLoadedError < RuntimeError; end

  module Backends
    @backends = {}

    def self.names
      @backends.keys
    end

    def self.register(backend_class)
      key = backend_class.name[/(?:::)?(\w+)\z/, 1]
      key.gsub!(/\A([A-Z])/) { $1.downcase }
      key.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      @backends[key] = backend_class
    end

    def self.find_backend_class(backend_name)
      case backend_name
      when Symbol
        backend_name = backend_name.to_s
      else
        backend_name = backend_name.to_str
      end
      unless @backends.has_key?(backend_name)
        begin
          require "charty/backends/#{backend_name}"
        rescue LoadError
          # nothing to do
        end
      end
      unless (backend_class = @backends[backend_name])
        raise BackendNotLoadedError, "Backend for '#{backend_name}' is not found."
      end
      backend_class
    end
  end
end
