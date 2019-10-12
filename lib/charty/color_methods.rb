module Charty
  module ColorMethods
    def RGB(*args)
      case args.length
      when 1
        case args[0]
        when Colors::AbstractColor
          args[0].to_rgb
        when ->(x) { x.respond_to?(:to_charty_rgb) }
          args[0].to_charty_rgb
        else
          raise ArgumentError, "the argument must be a color"
        end
      when 3
        Colors::RGB.new(*args)
      else
        raise ArgumentError,
              "wrong number of arguments (given #{args.length}, expected 1 or 3)"
      end
    end

    alias rgb RGB

    def RGBA(*args)
      case args.length
      when 1..2
        case args[0]
        when Colors::AbstractColor
          if args[1].is_a?(Hash)
            args[0].to_rgba(**args[1])
          else
            args[0].to_rgba
          end
        when ->(x) { x.respond_to?(:to_charty_rgba) }
          if args[1].is_a?(Hash)
            args[0].to_charty_rgba(**args[1])
          else
            args[0].to_charty_rgba
          end
        else
          raise ArgumentError, "the argument must be a color"
        end
      when 4
        Colors::RGBA.new(*args)
      else
        raise ArgumentError,
              "wrong number of arguments (given #{args.length}, expected 1, 2, or 4)"
      end
    end

    alias rgba RGBA

    def HSL(*args)
      case args.length
      when 1
        case args[0]
        when Colors::AbstractColor
          args[0].to_hsl
        when ->(x) { x.respond_to?(:to_charty_hsl) }
          args[0].to_charty_hsl
        else
          raise ArgumentError, "the argument must be a color"
        end
      when 3
        Colors::HSL.new(*args)
      else
        raise ArgumentError,
              "wrong number of arguments (given #{args.length}, expected 1 or 3)"
      end
    end

    alias hsl HSL

    def HSLA(*args)
      case args.length
      when 1..2
        case args[0]
        when Colors::AbstractColor
          if args[1].is_a?(Hash)
            args[0].to_hsla(**args[1])
          else
            args[0].to_hsla
          end
        when ->(x) { x.respond_to?(:to_charty_hsla) }
          if args[1].is_a?(Hash)
            args[0].to_charty_hsla(**args[1])
          else
            args[0].to_charty_hsla
          end
        else
          raise ArgumentError, "the argument must be a color"
        end
      when 4
        Colors::HSLA.new(*args)
      else
        raise ArgumentError,
              "wrong number of arguments (given #{args.length}, expected 1, 2, or 4)"
      end
    end

    alias hsla HSLA
  end

  extend ColorMethods
end
