module Visualizer
  class Linspace
    include Enumerable

    def initialize(range, num_step)
      @range = range
      @num_step = num_step
    end

    def each(&block)
      step = (@range.end - @range.begin).to_f / @num_step
      (@num_step - 1).times do |i|
        block.call(@range.begin + i * step)
      end

      unless @range.exclude_end?
        block.call(@range.end)
      end
    end
  end
end
