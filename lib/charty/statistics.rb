module Charty
  module Statistics
    begin
      require "enumerable/statistics"

      def self.mean(enum)
        enum.mean
      end

      def self.stdev(enum, population: false)
        enum.stdev(population: population)
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

    def self.bootstrap(vector, n_boot: 2000, func: :mean, units: nil, random: nil)
      n = vector.size
      random = Charty::Plotters::RandomSupport.check_random(random)
      func = Charty::Plotters::EstimationSupport.check_estimator(func)

      if units
        return structured_bootstrap(vector, n_boot, units, func, random)
      end

      if defined?(Pandas::Series) || defined?(Numpy::NDArray)
        boot_dist = bootstrap_optimized_for_pycall(vector, n_boot, random, func)
        return boot_dist if boot_dist
      end

      boot_dist = Array.new(n_boot) do |i|
        resampler = Array.new(n) { random.rand(n) }

        w ||= vector.values_at(*resampler)

        case func
        when :mean
          mean(w)
        end
      end

      boot_dist
    end

    private_class_method def self.bootstrap_optimized_for_pycall(vector, n_boot, random, func)
      case
      when vector.is_a?(Charty::Vector)
        bootstrap_optimized_for_pycall(vector.data, n_boot, random, func)

      when defined?(Pandas::Series) && vector.is_a?(Pandas::Series) || vector.is_a?(Numpy::NDArray)
        # numpy is also available when pandas is available
        n = vector.size
        resampler = Numpy.empty(n, dtype: Numpy.intp)
        Array.new(n_boot) do |i|
          # TODO: Use Numo and MemoryView to reduce execution time
          # resampler = Numo::Int64.new(n).rand(n)
          # w = Numpy.take(vector, resampler)
          n.times {|i| resampler[i] = random.rand(n) }
          w = vector.take(resampler)

          case func
          when :mean
            w.mean
          end
        end
      end
    end

    private_class_method def self.structured_bootstrap(vector, n_boot, units, func, random)
      raise NotImplementedError,
        "structured bootstrapping has not been supported yet"
    end

    def self.bootstrap_ci(*vectors, width, n_boot: 2000, func: :mean, units: nil, random: nil)
      boot = bootstrap(*vectors, n_boot: n_boot, func: func, units: units, random: random)
      q = [50 - width / 2, 50 + width / 2]
      if boot.respond_to?(:percentile)
        boot.percentile(q)
      else
        percentile(boot, q)
      end
    end

    # TODO: optimize with introselect algorithm
    def self.percentile(a, q)
      return mean(a) if a.size == 0

      a = a.sort
      n = a.size
      q.map do |x|
        x = n * (x / 100.0)
        i = x.floor
        if i == n-1
          a[i]
        else
          t = x - i
          (1-t)*a[i] + t*a[i+1]
        end
      end
    end
  end
end
