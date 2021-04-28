module Charty
  module Plotters
    module RandomSupport
      attr_reader :random

      def random=(random)
        @random = check_random(random)
      end

      module_function def check_random(random)
        case random
        when nil
          Random.new
        when Integer
          Random.new(random)
        when Random
          random
        else
          raise ArgumentError,
                "invalid value for random (%p for a generator or a seed value)" % value
        end
      end
    end
  end
end
