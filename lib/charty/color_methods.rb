module Charty
  module ColorMethods
    def RGB(*args)
      case args.length
      when 1
        begin
          args[0].to_rgb
        rescue NoMethodError
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
        begin
          if args[1].is_a?(Hash)
            args[0].to_rgba(**args[1])
          else
            args[0].to_rgba
          end
        rescue NoMethodError
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
        begin
          args[0].to_hsl
        rescue NoMethodError
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
        begin
          if args[1].is_a?(Hash)
            args[0].to_hsla(**args[1])
          else
            args[0].to_hsla
          end
        rescue NoMethodError
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

    def lookup_named_color(name)
      Colors::NamedColors[name]
    end
  end

  extend ColorMethods
end
