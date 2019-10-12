require_relative 'color_data'

module Charty
  module Colors
    module NamedColors
      class Mapping
        def initialize
          @mapping = {}
          @cache = {}
        end

        attr_reader :cache

        def [](name)
          if NamedColors.nth_color?(name)
            cycle = ColorData::DEFAULT_COLOR_CYCLE
            name = cycle[name[1..-1].to_i % cycle.length]
          end
          if cache.has_key?(name)
            cache[name]
          else
            cache[name] = lookup_no_color_cycle(name)
          end
        end

        private def lookup_no_color_cycle(color)
          orig_color = color
          case color
          when /\Anone\z/i
            return RGBA.new(0, 0, 0, 0)
          when String
            # nothing to do
          when Symbol
            color = color.to_s
          else
            color = color.to_str
          end
          color = @mapping.fetch(color, color)
          case color
          when /\A#\h+\z/
            case color.length - 1
            when 3, 6
              RGB.from_hex_string(color)
            when 4, 8
              RGBA.from_hex_string(color)
            else
              raise RuntimeError,
                    "[BUG] Invalid hex string form #{color.inspect} for #{name.inspect}"
            end
          when Array
            case color.length
            when 3
              RGB.new(*color)
            when 4
              RGBA.new(*color)
            else
              raise RuntimeError,
                    "[BUG] Invalid number of color components #{color} for #{name.inspect}"
            end
          else
            color
          end
        end

        def []=(name, value)
          @mapping[name] = value
        ensure
          cache.clear
        end

        def delete(name)
          @mapping.delete(name)
        ensure
          cache.clear
        end

        def update(other)
          @mapping.update(other)
        ensure
          cache.clear
        end
      end

      MAPPING = Mapping.new
      MAPPING.update(ColorData::XKCD_COLORS)
      ColorData::XKCD_COLORS.each do |key, value|
        MAPPING[key.sub("grey", "gray")] = value if key.include? "grey"
      end
      MAPPING.update(ColorData::CSS4_COLORS)
      MAPPING.update(ColorData::TABLEAU_COLORS)
      ColorData::TABLEAU_COLORS.each do |key, value|
        MAPPING[key.sub("gray", "grey")] = value if key.include? "gray"
      end
      MAPPING.update(ColorData::BASE_COLORS)

      def self.[](name)
        MAPPING[name]
      end

      # Return whether `name` is an item in the color cycle.
      def self.nth_color?(name)
        case name
        when String
          # do nothing
        when Symbol
          name = name.to_s
        else
          name = name.to_str
        end
        name.match?(/\AC\d+\z/)
      rescue NoMethodError, TypeError
        false
      end
    end
  end
end
