require_relative 'helper'

module Charty
  module Colors
    class RGB < AbstractColor
      include Helper

      def self.parse(hex_string)
        case hex_string.to_str.match(/\A#(\h+)\z/) { $1 }.length
        when 3  # rgb
          r, g, b = hex_string.scan(/\h/).map {|h| h.hex * 17 }
          new(r, g, b)
        when 6  # rrggbb
          r, g, b = hex_string.scan(/\h{2}/).map(&:hex)
          new(r, g, b)
        else
          raise ArgumentError, "Invalid hex string: #{hex_string.inspect}"
        end
      rescue NoMethodError
        raise ArgumentError, "hex_string must be a hexadecimal string of `#rrggbb` or `#rgb` form"
      end

      def initialize(r, g, b)
        @r, @g, @b = canonicalize(r, g, b)
      end

      attr_reader :r, :g, :b

      def components
        [r, g, b]
      end

      alias rgb_components components

      def r=(r)
        @r = canonicalize_component(r, :r)
      end

      def g=(g)
        @g = canonicalize_component(g, :g)
      end

      def b=(b)
        @b = canonicalize_component(b, :b)
      end

      alias red r
      alias green g
      alias blue b

      alias red= r=
      alias green= g=
      alias blue= b=

      def ==(other)
        case other
        when RGBA
          other == self
        when RGB
          r == other.r && g == other.g && b == other.b
        else
          super
        end
      end

      def desaturate(factor)
        to_hsl.desaturate(factor).to_rgb
      end

      def to_hex_string
        "##{components.map {|c| "%02x" % (255*c).round.to_i }.join('')}"
      end

      def to_rgb
        self
      end

      def to_rgba(alpha: 1.0)
        alpha = canonicalize_component(alpha, :alpha)
        RGBA.new(r, g, b, alpha)
      end

      def to_hsl
        HSL.new(*hsl_components)
      end

      def to_hsla(alpha: 1.0)
        alpha = canonicalize_component(alpha, :alpha)
        HSLA.new(*hsl_components, alpha)
      end

      def hsl_components
        m1, m2 = [r, g, b].minmax
        c = m2 - m1
        hh = case
             when c == 0
               0r
             when m2 == r
               ((g - b) / c) % 6r
             when m2 == g
               ((b - r) / c + 2) % 6r
             when m2 == b
               ((r - g) / c + 4) % 6r
             end
        h = 60r * hh
        l = 0.5r * m2 + 0.5r * m1
        s = if l == 1 || l == 0
              0r
            else
              c / (1 - (2*l - 1).abs)
            end
        [h, s, l]
      end

      def to_husl
        HUSL.from_rgb(r, g, b)
      end

      private def canonicalize(r, g, b)
        if [r, g, b].map(&:class) == [Integer, Integer, Integer]
          canonicalize_from_integer(r, g, b)
        else
          [
            canonicalize_component_to_rational(r, :r),
            canonicalize_component_to_rational(g, :g),
            canonicalize_component_to_rational(b, :b)
          ]
        end
      end

      private def canonicalize_from_integer(r, g, b)
        check_type(r, Integer, :r)
        check_type(g, Integer, :g)
        check_type(b, Integer, :b)
        [
          canonicalize_component_from_integer(r, :r),
          canonicalize_component_from_integer(g, :g),
          canonicalize_component_from_integer(b, :b)
        ]
      end
    end
  end
end
