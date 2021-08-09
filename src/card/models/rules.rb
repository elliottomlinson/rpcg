module Card
  module Models
    class SimpleRules
      attr_reader :text

      def initialize(text)
        @text = text
      end

      def ==(other)
        other.text == @text
      end
    end

    class HandCastRules
      attr_reader :hand, :cast

      def initialize(hand, cast)
        @hand = hand
        @cast = cast
      end

      def ==(other)
        other.hand == @hand &&
        other.cast == @cast
      end
    end
  end
end
