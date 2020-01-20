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

      attr_reader :x, :y, :color, :data, :palette

      def x=(x)
        @x = check_dimension(x, :x)
      end

      def y=(y)
        @y = check_dimension(y, :y)
      end

      def color=(color)
        # @color = check_dimension(color, :color)
        unless color.nil?
          raise NotImplementedError,
                "Specifying color variable is not supported yet"
        end
      end

      def data=(data)
        @data = case data
                when nil, Charty::Table
                  data
                else
                  Charty::Table.new(data)
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
