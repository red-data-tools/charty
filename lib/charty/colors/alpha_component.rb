module Charty
  module Colors
    module AlphaComponent
      attr_reader :a

      def a=(a)
        @a = if a.instance_of?(Integer)
               check_range(a, 0..255, :a) / 255r
             else
               Rational(check_range(a, 0..1, :a))
             end
      end

      alias alpha a

      alias alpha= a=
    end
  end
end
