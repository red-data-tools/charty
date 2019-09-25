module Charty
  module TestHelpers
    class LoadErrorBackend
      Backends.register(:load_error_backend, self)

      def self.prepare
        raise LoadError, "LoadErrorBackend"
      end
    end
  end
end
