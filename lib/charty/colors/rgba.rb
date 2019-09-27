module Charty
  module Colors
    class RGBA < RGB
      def self.from_hex_string(hex_string)
        case hex_string.to_str.match(/\A#(\h+)\z/) { $1 }.length
        when 3  # rgb
          r, g, b = hex_string.scan(/\h/).map {|h| h.hex * 17 }
          new(r, g, b, 255)
        when 6  # rrggbb
          r, g, b = hex_string.scan(/\h{2}/).map(&:hex)
          new(r, g, b, 255)
        when 4 # rgba
          r, g, b, a = hex_string.scan(/\h/).map {|h| h.hex * 17 }
          new(r, g, b, a)
        when 8 # rrggbbaa
          r, g, b, a = hex_string.scan(/\h{2}/).map(&:hex)
          new(r, g, b, a)
        else
          raise ArgumentError, "Invalid hex string: #{hex_string.inspect}"
        end
      rescue NoMethodError
        raise ArgumentError, "hex_string must be a hexadecimal string of `#rrggbb` or `#rgb` form"
      end

      def initialize(r, g, b, a)
        @r, @g, @b, @a = canonicalize(r, g, b, a)
      end

      def ==(other)
        case other
        when RGBA
          r == other.r && g == other.g && b == other.b && a == other.a
        else
          super
        end
      end

      attr_reader :a

      def a=(a)
        @a = if a.instance_of?(Integer)
               check_range(a, 0..255, :a) / 255r
             else
               Rational(check_range(a, 0..1, :a))
             end
      end

      alias alpha a

      alias alpha= a=

      def to_hex_string
        "##{[r, g, b, a].map {|c| "%02x" % (255*c).to_i }.join('')}"
      end

      private def canonicalize(r, g, b, a)
        if [r, g, b, a].map(&:class) == [Integer, Integer, Integer, Integer]
          canonicalize_from_integer(r, g, b, a)
        else
          [
            Rational(check_range(r, 0..1, :r)),
            Rational(check_range(g, 0..1, :g)),
            Rational(check_range(b, 0..1, :b)),
            Rational(check_range(a, 0..1, :a))
          ]
        end
      end

      private def canonicalize_from_integer(r, g, b, a)
        check_type(r, Integer, :r)
        check_type(g, Integer, :g)
        check_type(b, Integer, :b)
        check_type(a, Integer, :a)
        [
          check_range(r, 0..255, :r)/255r,
          check_range(g, 0..255, :g)/255r,
          check_range(b, 0..255, :b)/255r,
          check_range(a, 0..255, :a)/255r
        ]
      end
    end
  end
end
