module Charty
  module Colors
    class RGB
      def self.from_hex_string(hex_string)
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

      attr_reader :r, :g, :b

      def r=(r)
        @r = if r.instance_of?(Integer)
               check_range(r, 0..255, :r) / 255r
             else
               Rational(check_range(r, 0..1, :r))
             end
      end

      def g=(g)
        @g = if g.instance_of?(Integer)
               check_range(g, 0..255, :g) / 255r
             else
               Rational(check_range(g, 0..1, :g))
             end
      end

      def b=(b)
        @b = if b.instance_of?(Integer)
               check_range(b, 0..255, :b) / 255r
             else
               Rational(check_range(b, 0..1, :b))
             end
      end

      alias red r
      alias green g
      alias blue b

      alias red= r=
      alias green= g=
      alias blue= b=

      def to_hex_string
        "##{[r, g, b].map {|c| "%02x" % (255*c).to_i }.join('')}"
      end

      def to_rgba(alpha: 1.0)
        case alpha
        when Integer
          alpha = check_range(alpha, 0..255, :alpha)/255r
        else
          alpha = Rational(check_range(alpha, 0..1, :alpha))
        end
        RGBA.new(r, g, b, alpha)
      end

      private def canonicalize(r, g, b)
        if [r, g, b].map(&:class) == [Integer, Integer, Integer]
          canonicalize_from_integer(r, g, b)
        else
          [
            Rational(check_range(r, 0..1, :r)),
            Rational(check_range(g, 0..1, :g)),
            Rational(check_range(b, 0..1, :b))
          ]
        end
      end

      private def canonicalize_from_integer(r, g, b)
        check_type(r, Integer, :r)
        check_type(g, Integer, :g)
        check_type(b, Integer, :b)
        [
          check_range(r, 0..255, :r)/255r,
          check_range(g, 0..255, :g)/255r,
          check_range(b, 0..255, :b)/255r
        ]
      end

      private def check_type(obj, type, name)
        return obj if obj.instance_of?(Integer)
        check_fail TypeError, "#{name} must be a #{type}"
      end

      private def check_range(value, range, name)
        return value if range.cover?(value)
        check_fail ArgumentError, "#{name} must be in #{range}"
      end

      private def check_fail(exc_class, *args)
        exc = exc_class.new(*args)
        exc.set_backtrace(caller(2))
        raise exc
      end
    end
  end
end
