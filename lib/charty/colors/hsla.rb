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

      def to_hsla
        self
      end

      def to_rgba
        Charty::Colors::RGBA.new(*convert_to_rgb, a)
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
                "Unable to convert non-opaque HSLA to HSL"
        end
      end

      private def canonicalize(h, s, l, a)
        if [s, l, a].map(&:class) == [Integer, Integer, Integer]
          canonicalize_from_integer(h, s, l, a)
        else
          [
            Rational(h) % 360,
            Rational(check_range(s, 0..1, :s)),
            Rational(check_range(l, 0..1, :l)),
            Rational(check_range(a, 0..1, :a)),
          ]
        end
      end

      private def canonicalize_from_integer(h, s, l, a)
        check_type(s, Integer, :s)
        check_type(l, Integer, :l)
        check_type(a, Integer, :a)
        [
          Rational(h) % 360,
          check_range(s, 0..255, :s)/255r,
          check_range(l, 0..255, :l)/255r,
          check_range(a, 0..255, :a)/255r
        ]
      end
    end
  end
end
