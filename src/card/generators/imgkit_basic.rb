require 'bundler/setup'
require "imgkit"
require "mustache"

module Card
  module Generators
    class IMGKitBasic
      def initialize(template_function, stylesheets)
        @template_function = template_function
        @stylesheets = stylesheets
      end

      def generate(card_specification, output_path)
        MustacheCard.template_file = @template_function.call(card_specification) 

        html = render_mustache(card_specification)

        kit = IMGKit.new(html)

        kit.to_file(output_path)
      end

      private

      def render_mustache(card_specification)
        MustacheCard.render(
          title: card_specification.title,
          rules: generate_rules_content(card_specification.rules),
          upgrade: card_specification.upgrade,
          flavour: card_specification.flavour,
          art_path: card_specification.art_path
        )
      end

      def generate_rules_content(rules)
        case rules
        when Card::Models::SimpleRules
          rules.text
        when Card::Models::HandCastRules
          "✋: #{rules.hand}
⚡: #{rules.cast}"
        else
          raise "Unsupported rule type #{rules.class}"
        end
      end

      class MustacheCard < Mustache
        attr_accessor :title, :rules, :upgrade, :flavour, :art_path
      end
    end
  end
end
