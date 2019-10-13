module Charty
  module BackendMethods
    def use_backend(backend)
      if block_given?
        begin
          saved, Backends.current = Backends.current, backend
          yield
        ensure
          Backends.current = saved
        end
      else
        Backends.current = backend
      end
    end
  end

  extend BackendMethods
end
