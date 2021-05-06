module Charty
  module Plotters
    module EstimationSupport
      attr_reader :estimator

      def estimator=(estimator)
        @estimator = check_estimator(estimator)
      end

      module_function def check_estimator(value)
        case value
        when :count, "count"
          :count
        when :mean, "mean"
          :mean
        when :median
          raise NotImplementedError,
                "median estimator has not been supported yet"
        when Proc
          raise NotImplementedError,
                "a callable estimator has not been supported yet"
        else
          raise ArgumentError,
                "invalid value for estimator (%p for :mean)" % value
        end
      end

      attr_reader :ci

      def ci=(ci)
        @ci = check_ci(ci)
      end

      private def check_ci(value)
        case value
        when nil
          nil
        when :sd, "sd"
          :sd
        when 0..100
          value
        when Numeric
          raise ArgumentError,
                "ci must be in 0..100, but %p is given" % value
        else
          raise ArgumentError,
                "invalid value for ci (%p for nil, :sd, or a number in 0..100)" % value
        end
      end

      attr_reader :n_boot

      def n_boot=(n_boot)
        @n_boot = check_n_boot(n_boot)
      end

      private def check_n_boot(value)
        case value
        when Integer
          if value <= 0
            raise ArgumentError,
                  "n_boot must be larger than zero, but %p is given" % value
          end
          value
        else
          raise ArgumentError,
                "invalid value for n_boot (%p for an integer > 0)" % value
        end
      end

      attr_reader :units

      def units=(units)
        @units = check_dimension(units, :units)
        unless units.nil?
          raise NotImplementedError,
                "Specifying units variable is not supported yet"
        end
      end

      include RandomSupport
    end
  end
end
