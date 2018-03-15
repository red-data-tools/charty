module RedVisualizer
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
      end
    end

    def <<(content)
      @layout << content
    end

    def render
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
end
