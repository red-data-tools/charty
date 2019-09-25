module Charty
  class BackendError < RuntimeError; end
  class BackendNotFoundError < BackendError; end
  class BackendLoadError < BackendError; end

  module Backends
    @backends = {}

    def self.names
      @backends.keys
    end

    def self.register(name, backend_class)
      @backends[normalize_name(name)] = {
        class: backend_class,
        prepared: false,
      }
    end

    def self.find_backend_class(name)
      backend = @backends[normalize_name(name)]
      unless backend
        raise BackendNotFoundError, "Backend is not found: #{name.inspect}"
      end
      backend_class = backend[:class]
      unless backend[:prepared]
        if backend_class.respond_to?(:prepare)
          begin
            backend_class.prepare
          rescue LoadError
            raise BackendLoadError, "Backend load error: #{name.inspect}"
          end
        end
        backend[:prepared] = true
      end
      backend_class
    end

    private_class_method def self.normalize_name(name)
      case name
      when Symbol
        name.to_s
      else
        name.to_str
      end
    end
  end
end

require "charty/backends/bokeh"
require "charty/backends/google_chart"
require "charty/backends/gruff"
require "charty/backends/plotly"
require "charty/backends/pyplot"
require "charty/backends/rubyplot"
