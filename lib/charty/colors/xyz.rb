require_relative "helper"

require "numo/narray"

module Charty
  module Colors
    XYZ2RGB = Numo::DFloat[
      [  3.24096994190452134377, -1.53738317757009345794, -0.49861076029300328366 ],
      [ -0.96924363628087982613,  1.87596750150772066772,  0.04155505740717561247 ],
      [  0.05563007969699360846, -0.20397695888897656435,  1.05697151424287856072 ]
    ]

    RGB2XYZ = Numo::DFloat[
      [  0.41239079926595948129,  0.35758433938387796373,  0.18048078840183428751 ],
      [  0.21263900587151035754,  0.71516867876775592746,  0.07219231536073371500 ],
      [  0.01933081871559185069,  0.11919477979462598791,  0.95053215224966058086 ]
    ]

    class XYZ < AbstractColor
      include Helper

      EPSILON = (6/29r)**3

      KAPPA = (29/3)**3

      def self.from_xyY(x, y, large_y)
        large_x = large_y*x/y
        large_z = large_y*(1 - x - y)/y
        new(large_x, large_y, large_z)
      end

      def self.from_rgb(r, g, b)
        c = RGB2XYZ.dot(Numo::DFloat[to_linear(r), to_linear(g), to_linear(b)])
        new(c[0], c[1], c[2])
      end

      private_class_method def self.to_linear(v)
        if v > 0.04045
          ((v + 0.055r) / 1.055r) ** 2.4r
        else
          v / 12.92r
        end
      end

      def initialize(x, y, z)
        @x, @y, @z = canonicalize(x, y, z)
      end

      attr_reader :x, :y, :z

      def components
        [x, y, z]
      end

      def ==(other)
        case other
        when XYZ
          x == other.x && y == other.y && z == other.z
        else
          super
        end
      end

      def to_rgb
        Charty::Colors::RGB.new(*rgb_components)
      end

      def rgb_components
        c = XYZ2RGB.dot(Numo::DFloat[x, y, z])
        [
          srgb_compand(c[0]).clamp(0r, 1r),
          srgb_compand(c[1]).clamp(0r, 1r),
          srgb_compand(c[2]).clamp(0r, 1r)
        ]
      end

      def luv_components(wp)
        yy = y/wp.y
        uu, vv = uv_values
        l = if yy <= EPSILON
              KAPPA * yy
            else
              116 * Math.cbrt(yy).to_r - 16
            end
        if l <= 1e-8
          u = v = 0r
        else
          wp_u, wp_v = wp.uv_values
          u = 13*l*(uu - wp_u)
          v = 13*l*(vv - wp_v)
        end
        [l, u, v]
      end

      def uv_values
        d = x + 15*y + 3*z
        return [0r, 0r] if d == 0
        u = 4*x / d
        v = 9*y / d
        [u, v]
      end

      private def srgb_compand(v)
        # the following is an optimization technique for `1.055*v**(1/2.4) - 0.055`.
        # x^y ~= exp(y*log(x)) ~= exp2(y*log2(y)); the middle form is faster
        #
        # See https://github.com/JuliaGraphics/Colors.jl/issues/351#issuecomment-532073196
        # for more detail benchmark in Julia language.
        if v <= 0.0031308
          12.92*v
        else
          1.055 * Math.exp(1/2.4 * Math.log(v)) - 0.055
        end
      end

      private def canonicalize(x, y, z)
        [
          Rational(x),
          Rational(y),
          Rational(z)
        ]
      end
    end
  end
end
