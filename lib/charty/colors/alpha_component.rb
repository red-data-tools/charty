module Charty
  module Colors
    module AlphaComponent
      attr_reader :a

      def a=(a)
        @a = canonicalize_component(a, :a)
      end

      alias alpha a

      alias alpha= a=
    end
  end
end
