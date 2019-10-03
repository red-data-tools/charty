require_relative "colors/helper"
require_relative "colors/alpha_component"

require_relative "colors/abstract_color"
require_relative "colors/xyz"
require_relative "colors/rgb"
require_relative "colors/rgba"
require_relative "colors/hsl"
require_relative "colors/hsla"
require_relative "colors/husl"

require_relative "colors/named_colors"

module Charty
  module Colors
    # ITU-R BT.709 D65 white point
    # See https://en.wikipedia.org/wiki/Rec._709 for details
    WHITE_POINT_D65 = Colors::XYZ.from_xyY(0.3127r, 0.3290r, 1r)

    def self.desaturate(c, factor)
      case c
      when String
        c = NamedColors[c]
      end
      c.desaturate(factor)
    end
  end
end
