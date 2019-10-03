module Charty
  module Colors
    class AbstractColor
      def desaturate(factor)
        unsupported __method__
      end

      private

      def unsupported(name)
        exc = NotImplementedError.new("#{name} is unsupported in #{self.class}")
        exc.set_backtrace(caller(2))
        raise exc
      end
    end
  end
end
