module Charty
  module Plotters
    class AbstractPlotter
      def initialize(x, y, color, **options)
        self.x = x
        self.y = y
        self.color = color
        self.data = data
        self.palette = palette
        substitute_options(options)
        yield self if block_given?
      end

      attr_reader :data, :x, :y, :color
      attr_reader :color_order, :key_color, :palette

      def data=(data)
        @data = case data
                when nil, Charty::Table
                  data
                else
                  Charty::Table.new(data)
                end
      end

      def x=(x)
        @x = check_dimension(x, :x)
      end

      def y=(y)
        @y = check_dimension(y, :y)
      end

      def color=(color)
        @color = check_dimension(color, :color)
      end

      def color_order=(color_order)
        #@color_order = XXX
        unless color_order.nil?
          raise NotImplementedError,
                "Specifying color_order is not supported yet"
        end
      end

      def key_color=(key_color)
        #@key_color = XXX
        unless key_color.nil?
          raise NotImplementedError,
                "Specifying key_color is not supported yet"
        end
      end

      def palette=(palette)
        @palette = case palette
                   when nil, Palette, Symbol, String
                     palette
                   else
                     raise ArgumentError,
                       "invalid type for palette (given #{palette.class}, " +
                       "expected Palette, Symbol, or String)"
                   end
      end

      private def substitute_options(options)
        options.each do |key, val|
          send("#{key}=", val)
        end
      end

      private def check_dimension(value, name)
        case value
        when nil, Symbol, String, method(:array?)
          value
        when ->(x) { x.respond_to?(:to_str) }
          value.to_str
        else
          raise ArgumentError,
                "invalid type of dimension for #{name} (given #{value.inspect})",
                caller
        end
      end

      private def check_number(value, name, allow_nil: false)
        case value
        when Numeric
          value
        else
          if allow_nil && value.nil?
            nil
          else
            expected = if allow_nil
                         "number or nil"
                       else
                         "number"
                       end
            raise ArgumentError,
                  "invalid value for #{name} (%p for #{expected})" % value,
                  caller
          end
        end
      end

      private def check_boolean(value, name, allow_nil: false)
        case value
        when true, false
          value
        else
          expected = if allow_nil
                       "true, false, or nil"
                     else
                       "true or false"
                     end
          raise ArgumentError,
                "invalid value for #{name} (%p for #{expected})" % value,
                caller
        end
      end

      private def array?(value)
        TableAdapters::HashAdapter.array?(value)
      end

      def to_iruby
        result = render
        ["text/html", result] if result
      end
    end
  end
end
