module Charty
  module Statistics
    begin
      require "enumerable/statistics"

      def self.mean(enum)
        enum.mean
      end

      def self.stdev(enum)
        enum.stdev
      end
    rescue LoadError
      def self.mean(enum)
        xs = enum.to_a
        xs.sum / xs.length.to_f
      end

      def self.stdev(enum, population: false)
        xs = enum.to_a
        n = xs.length
        mean = xs.sum.to_f / n
        ddof = population ? 0 : 1
        var = xs.map {|x| (x - mean)**2 }.sum / (n - ddof)
        Math.sqrt(var)
      end
    end
  end
end
