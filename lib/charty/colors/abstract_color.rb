module Charty
  module Colors
    class AbstractColor
      def desaturate(factor)
        unsupported __method__
      end

      private def unsupported(name)
        raise NotImplementedError, "#{name} is unsupported in #{self.class}", caller(2)
      end

      private def canonicalize_component(value, name)
        case value
        when Integer
          canonicalize_component_from_integer(value, name)
        else
          canonicalize_component_to_rational(value, name)
        end
      end

      private def canonicalize_component_from_integer(value, name)
        check_range(value, 0..255, name)/255r
      end

      private def canonicalize_component_to_rational(value, name)
        Rational(check_range(value, 0..1, name))
      end
    end
  end
end
