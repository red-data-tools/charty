module Charty
  module DashPatternGenerator
    NAMED_PATTERNS = {
            solid: "",
             dash: [4, 1.5],
              dot:  [1, 1],
          dashdot: [3, 1.25, 1.5, 1.25],
      longdashdot: [5, 1, 1, 1],
    }.freeze

    def self.valid_name?(name)
      name = case name
             when Symbol, String
               name.to_sym
             else
               name.to_str.to_sym
             end
      NAMED_PATTERNS.key?(name)
    end

    def self.pattern_to_name(pattern)
      NAMED_PATTERNS.each do |key, val|
        return key if pattern == val
      end
      nil
    end

    def self.each
      return enum_for(__method__) unless block_given?

      NAMED_PATTERNS.each_value do |pattern|
        yield pattern
      end

      m = 3
      while true
        # Long and short dash combinations
        a = [3, 1.25].repeated_combination(m).to_a[1..-2].reverse
        b = [4, 1].repeated_combination(m).to_a[1..-2]

        # Interleave these combinations
        segment_list = a.zip(b).flatten(1)

        # Insert the gaps
        segment_list.each do |segment|
          gap = segment.min
          pattern = segment.map {|seg| [seg, gap] }.flatten
          yield pattern
        end

        m += 1
      end
    end

    extend Enumerable
  end
end
