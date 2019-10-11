module Charty
  module Colors
    class HSLA < HSL
      def initialize(h, s, l, a)
        @h, @s, @l, @a = canonicalize(h, s, l, a)
      end

      include AlphaComponent

      def components
        [h, s, l, a]
      end

      alias hsla_components components

      def ==(other)
        case other
        when HSLA
          h == other.h && s == other.s && l == other.l && a == other.a
        when HSL
          h == other.h && s == other.s && l == other.l && a == 1r
        else
          super
        end
      end

      def desaturate(factor)
        HSLA.new(h, s*factor, l, a)
      end

      def to_hsla
        self
      end

      def to_rgba
        Charty::Colors::RGBA.new(*rgb_components, a)
      end

      def to_hsl
        if a == 1r
          super
        else
          raise NotImplementedError,
                "Unable to convert non-opaque HSLA to HSL"
        end
      end

      def to_rgb
        if a == 1r
          super
        else
          raise NotImplementedError,
                "Unable to convert non-opaque HSLA to RGB"
        end
      end

      private def canonicalize(h, s, l, a)
        if [s, l, a].map(&:class) == [Integer, Integer, Integer]
          canonicalize_from_integer(h, s, l, a)
        else
          [
            Rational(h) % 360,
            canonicalize_component_to_rational(s, :s),
            canonicalize_component_to_rational(l, :l),
            canonicalize_component_to_rational(a, :a)
          ]
        end
      end

      private def canonicalize_from_integer(h, s, l, a)
        check_type(s, Integer, :s)
        check_type(l, Integer, :l)
        check_type(a, Integer, :a)
        [
          Rational(h) % 360,
          canonicalize_component_from_integer(s, :s),
          canonicalize_component_from_integer(l, :l),
          canonicalize_component_from_integer(a, :a)
        ]
      end
    end
  end
end
