module Charty
  module Colors
    class HSL < AbstractColor
      include Helper

      def initialize(h, s, l)
        @h, @s, @l = canonicalize(h, s, l)
      end

      attr_reader :h, :s, :l

      def components
        [h, s, l]
      end

      alias hsl_components components

      def h=(h)
        @h = Rational(h) % 360
      end

      def s=(s)
        @s = if s.instance_of?(Integer)
               check_range(s, 0..255, :s) / 255r
             else
               Rational(check_range(s, 0..1, :s))
             end
      end

      def l=(l)
        @l = if l.instance_of?(Integer)
               check_range(l, 0..255, :l) / 255r
             else
               Rational(check_range(l, 0..1, :l))
             end
      end

      alias hue h
      alias saturation s
      alias lightness l

      alias hue= h=
      alias saturation= s=
      alias lightness= l=

      def ==(other)
        case other
        when HSLA
          other == self
        when HSL
          h == other.h && s == other.s && l == other.l
        else
          super
        end
      end

      def desaturate(factor)
        HSL.new(h, s*factor, l)
      end

      def to_hsl
        self
      end

      def to_hsla(alpha: 1.0)
        alpha = canonicalize_component(alpha, :alpha)
        Charty::Colors::HSLA.new(h, s, l, alpha)
      end

      def to_rgb
        Charty::Colors::RGB.new(*rgb_components)
      end

      def to_rgba(alpha: 1.0)
        alpha = canonicalize_component(alpha, :alpha)
        Charty::Colors::RGBA.new(*rgb_components, alpha)
      end

      def rgb_components
        t2 = if l <= 0.5r
               l * (s + 1r)
             else
               l + s - l * s
             end
        t1 = l * 2r - t2
        hh = h/60r
        r = hue_to_rgb(t1, t2, hh + 2)
        g = hue_to_rgb(t1, t2, hh)
        b = hue_to_rgb(t1, t2, hh - 2)
        [r, g, b]
      end

      private def hue_to_rgb(t1, t2, h)
        h += 6r if h < 0
        h -= 6r if h >= 6
        if h < 1
          (t2 - t1) * h + t1
        elsif h < 3
          t2
        elsif h < 4
          (t2 - t1) * (4r - h) + t1
        else
          t1
        end
      end

      private def canonicalize(h, s, l)
        if [s, l].map(&:class) == [Integer, Integer]
          canonicalize_from_integer(h, s, l)
        else
          [
            Rational(h) % 360,
            canonicalize_component_to_rational(s, :s),
            canonicalize_component_to_rational(l, :l)
          ]
        end
      end

      private def canonicalize_from_integer(h, s, l)
        check_type(s, Integer, :s)
        check_type(l, Integer, :l)
        [
          Rational(h) % 360,
          canonicalize_component_from_integer(s, :s),
          canonicalize_component_from_integer(l, :l)
        ]
      end
    end
  end
end
