require "numo/narray"

module Charty
  module Colors
    # Human-friendly alternative to HSL color space.
    # The definition of HUSL is provided in <http://www.hsluv.org>.
    class HUSL < HSL
      DEG2RAD = 0.01745329251994329577r  # 2 * pi / 360

      def self.from_rgb(r, g, b)
        c = Colors::XYZ.from_rgb(r, g, b)
        l, u, v = c.luv_components(Charty::Colors::WHITE_POINT_D65)
        l, c, h = convert_luv_to_lch(l, u, v)
        h, s, l = convert_lch_to_husl(l, c, h)
        new(h.to_r % 360r, s.to_r.clamp(0r, 1r), l.to_r.clamp(0r, 1r))
      end

      private_class_method def self.convert_luv_to_lch(l, u, v)
        c = Math.sqrt(u*u + v*v).to_r

        if c < 1e-8
          h = 0r
        else
          h = Math.atan2(v, u).to_r * 180/Math::PI.to_r
          h += 360r if h < 0
        end

        [l, c, h]
      end

      private_class_method def self.convert_lch_to_husl(l, c, h)
        if l > 99.9999999 || l < 1e-8
          s = 0r
        else
          mx = max_chroma(l, h)
          s = c / mx * 100r
        end

        h = 0r if c < 1e-8

        [h, s/100r, l/100r]
      end

      def ==(other)
        case other
        when HUSL
          h == other.h && s == other.s && l == other.l
        else
          other == self
        end
      end

      def desaturate(factor)
        to_rgb.desaturate(factor).to_husl
      end

      def to_husl
        self
      end

      def to_rgb
        Colors::RGB.new(*convert_to_rgb)
      end

      private def convert_to_rgb
        l, c, h = convert_to_lch
        l, u, v = convert_lch_to_luv(l, c, h)
        x, y, z = convert_luv_to_xyz(l, u, v)
        Colors::XYZ.new(x, y, z).to_rgb_values
      end

      private def convert_to_lch
        l = self.l * 100r
        s = self.s * 100r

        if l > 99.9999999 || l < 1e-8
          c = 0r
        else
          mx = self.class.max_chroma(l, h)
          c = mx / 100r * s
        end

        h = s < 1e-8 ? 0r : self.h

        [l, c, h]
      end

      private def convert_lch_to_luv(l, c, h)
        h_rad = h * DEG2RAD
        u = Math.cos(h_rad).to_r * c
        v = Math.sin(h_rad).to_r * c
        [l, u, v]
      end

      private def convert_luv_to_xyz(l, u, v)
        return [0r, 0r, 0r] if l <= 1e-8

        wp_u, wp_v = WHITE_POINT_D65.uv_values
        var_u = u / (13 * l) + wp_u
        var_v = v / (13 * l) + wp_v
        y = if l < 8
              l / Colors::CYZ::KAPPA
            else
              ((l + 16r) / 116r)**3
            end
        x = -(9 * y * var_u) / ((var_u - 4) * var_v - var_u * var_v)
        z = (9 * y - (15 * var_v * y) - (var_v * x)) / (3 * var_v)
        [x, y, z]
      end

      def self.max_chroma(l, h)
        h_rad = h * DEG2RAD
        sin_h = Math.sin(h_rad).to_r
        cos_h = Math.cos(h_rad).to_r

        result = Float::INFINITY
        get_bounds(l).each do |line|
          len = line[1] / (sin_h - line[0] * cos_h)
          result = len if 0 <= len && len < result
        end
        result
      end

      def self.get_bounds(l)
        sub1 = (l + 16)**3 / 1560896r
        sub2 = sub1 > Colors::XYZ::EPSILON ? sub1 : l/Colors::XYZ::KAPPA

        bounds = Array.new(6) { [0r, 0r] }
        0.upto(2) do |ch|
          m1 = XYZ2RGB[ch, 0].to_r
          m2 = XYZ2RGB[ch, 1].to_r
          m3 = XYZ2RGB[ch, 2].to_r

          [0, 1].each do |t|
            top1 = (284517r * m1 - 94839r * m3) * sub2
            top2 = (838422r * m3 + 769860r * m2 + 731718r * m1) * l * sub2 - 769860r * t * l
            bottom = (632260r * m3 - 126452r * m2) * sub2 + 126452r * t

            bounds[ch*2 + t][0] = top1 / bottom
            bounds[ch*2 + t][1] = top2 / bottom
          end
        end
        bounds
      end
    end
  end
end
