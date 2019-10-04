module Charty
  module Colors
    module Helper
      private def check_type(obj, type, name)
        return obj if obj.instance_of?(Integer)
        check_fail TypeError, "#{name} must be a #{type}, but #{obj.class} is given"
      end

      private def check_range(value, range, name)
        return value if range.cover?(value)
        check_fail ArgumentError, "#{name} must be in #{range}, but #{value} is given"
      end

      private def check_fail(exc_class, *args)
        exc = exc_class.new(*args)
        exc.set_backtrace(caller(2))
        raise exc
      end
    end
  end
end
