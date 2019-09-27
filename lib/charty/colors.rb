require_relative "colors/rgb"
require_relative "colors/rgba"

module Charty
  class << self
    def RGB(*args)
      case args.length
      when 1
        begin
          return args[0].to_rgb
        rescue NoMethodError
          raise ArgumentError, "the argument must be a color"
        end
      when 3
        return Colors::RGB.new(*args)
      end
      raise ArgumentError,
            "wrong number of arguments (#{args.length} for 1 or 3)"
    end

    alias rgb RGB

    def RGBA(*args)
      case args.length
      when 1..2
        begin
          if args[1].is_a?(Hash)
            return args[0].to_rgba(**args[1])
          else
            return args[0].to_rgba
          end
        rescue NoMethodError
          raise ArgumentError, "the argument must be a color"
        end
      when 4
        return Colors::RGBA.new(*args)
      end
      raise ArgumentError,
            "wrong number of arguments (#{args.length} for 1 or 3)"
    end

    alias rgba RGBA
  end
end
