module Charty
  module Colors
    module Helper
      private def check_type(obj, type, name)
        return obj if obj.instance_of?(type)
        check_fail TypeError, "#{name} must be a #{type}, but #{obj.class} is given"
      end

      private def check_range(value, range, name)
        return value if range.cover?(value)
        check_fail ArgumentError, "#{name} must be in #{range}, but #{value} is given"
      end

      private def check_fail(exc_class, message)
        raise exc_class, message, caller(2)
      end
    end
  end
end
