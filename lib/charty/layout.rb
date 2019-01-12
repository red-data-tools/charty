module Charty
  class Layout
    def initialize(frontend, definition = :horizontal)
      @frontend = frontend
      @layout = parse_definition(definition)
    end

    def parse_definition(definition)
      case definition
      when :horizontal
        ArrayLayout.new
      when :vertical
        ArrayLayout.new(:vertical)
      else
        if match = definition.to_s.match(/\Agrid(\d+)x(\d+)\z/)
          num_cols = match[1].to_i
          num_rows = match[2].to_i
          GridLayout.new(num_cols, num_rows)
        end
      end
    end

    def <<(content)
      if content.respond_to?(:each)
        content.each {|c| self << c }
      else
        @layout << content
      end
      nil
    end

    def render(filename="")
      @frontend.render_layout(@layout)
    end
  end

  class ArrayLayout
    def initialize(direction=:horizontal)
      @array = []
      @direction = direction
    end

    def <<(content)
      @array << content
    end

    def num_rows
      @direction == :horizontal ? 1 : @array.count
    end

    def num_cols
      @direction == :vertical ? 1 : @array.count
    end

    def rows
      [@array]
    end
  end

  class GridLayout
    attr_reader :num_rows, :num_cols, :rows

    def initialize(num_cols, num_rows)
      @rows = Array.new(num_rows) { Array.new(num_cols) }
      @num_cols = num_cols
      @num_rows = num_rows
      @cursor = 0
    end

    def <<(content)
      @rows[@cursor / @num_rows][@cursor % @num_cols] = content
      @cursor += 1
    end
  end
end
