module Charty
  module Colors
    class HSL
      include Helper

      def initialize(h, s, l)
        @h, @s, @l = canonicalize(h, s, l)
      end

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

      attr_reader :h, :s, :l

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

      def to_hsl
        self
      end

      def to_hsla(alpha: 1.0)
        case alpha
        when Integer
          alpha = check_range(alpha, 0..255, :alpha) / 255r
        else
          alpha = Rational(check_range(alpha, 0..1, :alpha))
        end
        Charty::Colors::HSLA.new(h, s, l, alpha)
      end

      def to_rgb
        Charty::Colors::RGB.new(*convert_to_rgb)
      end

      def to_rgba
        Charty::Colors::RGBA.new(*convert_to_rgb, 1r)
      end

      private def convert_to_rgb
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
            Rational(check_range(s, 0..1, :s)),
            Rational(check_range(l, 0..1, :l))
          ]
        end
      end

      private def canonicalize_from_integer(h, s, l)
        check_type(s, Integer, :s)
        check_type(l, Integer, :l)
        [
          Rational(h) % 360,
          check_range(s, 0..255, :s)/255r,
          check_range(l, 0..255, :l)/255r
        ]
      end
    end
  end
end
