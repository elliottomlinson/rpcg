require 'bundler/setup'
require "ruby-vips"

# todo: move these into central spec
CARD_BORDER = 50
CARD_WIDTH = 668
TITLE_HEIGHT = 100
CARD_ART_HEIGHT = 477
TYPE_INFO_HEIGHT = 60
RULES_HEIGHT = 287
TITLE_BORDER = 20
TITLE_BOX_IMAGE = "res/card/template/title_box.png"
TYPE_BOX_IMAGE = "res/card/template/type_box.png"
DESCRIPTION_BOX_IMAGE = "res/card/template/description_box.png"
BORDER_IMAGES = {
  grey: "res/card/template/background-grey.png",
  blue: "res/card/template/background-blue.png",
  green: "res/card/template/background-green.png",
  pink: "res/card/template/background-pink.png",
  red: "res/card/template/background-red.png",
  gold: "res/card/template/background-gold.png",
}

TITLE_FONT = "Karmatic Arcade" # https://www.dafont.com/karmatic-arcade.font
TYPE_FONT = "Libre Baskerville" # https://github.com/impallari/Libre-Baskerville/blob/master/LibreBaskerville-Regular.ttf
RULES_FONT = "EB Garamond" # https://fonts.google.com/specimen/EB+Garamond
TITLE_DPI = 350
TYPE_DPI = 300
RULES_DPI = 300

# Generates and saves a card image using the libvips library
# All images which are too large will be top-left cropped to size
# All images which are too small will crash the program

module Card
  module Generators
    class VipsBasic
      def generate(card, output_path)
        raise "inputted card is not a CardSpecification" unless card.is_a?(Card::Models::CardSpecification)

        title_box = generate_title_box(card.title)
        art_box = generate_art_box(card.art_path)
        type_box = generate_type_box(card.typeline)
        rules_box = generate_rules_box(card.rules, card.flavour)

        card_content = [title_box, art_box, type_box, rules_box].reduce do |image, box|
          image.join(box, :vertical)
        end

        card_image = wrap_content_with_border(card_content, card.tier)

        card_image.write_to_file(output_path)
      end

      private

      def generate_title_box(title)
        generate_simple_text(
          title,
          load_at_size(TITLE_BOX_IMAGE, CARD_WIDTH, TITLE_HEIGHT),
          TITLE_FONT,
          CARD_WIDTH - TITLE_BORDER,
          TITLE_HEIGHT - TITLE_BORDER,
          TITLE_DPI,
          :centre
        )
      end

      def generate_art_box(art_path)
        load_at_size(art_path, CARD_WIDTH, CARD_ART_HEIGHT)
      end

      def generate_type_box(typeline)
        generate_simple_text(
          typeline,
          load_at_size(TYPE_BOX_IMAGE, CARD_WIDTH, TYPE_INFO_HEIGHT),
          TYPE_FONT,
          CARD_WIDTH - TITLE_BORDER,
          TYPE_INFO_HEIGHT - TITLE_BORDER,
          TYPE_DPI
        )
      end

      def generate_rules_box(rules, flavour)
        rules_box_content = generate_rules_content(rules)

        description_text = flavour.nil? ?
          rules :
          "<span foreground='blue'>#{rules_box_content}</span>\n\n<span style='italic'>#{flavour}</span>"

        generate_simple_text(
          description_text,
          load_at_size(DESCRIPTION_BOX_IMAGE, CARD_WIDTH, RULES_HEIGHT),
          RULES_FONT,
          CARD_WIDTH - TITLE_BORDER,
          RULES_HEIGHT - TITLE_BORDER,
          RULES_DPI
        )
      end

      def wrap_content_with_border(image, tier)
        border_layer = load_at_size(
          BORDER_IMAGES[tier],
          image.width + CARD_BORDER*2,
          image.height + CARD_BORDER*2,
        )

        center_overlay(border_layer, image)
      end

      def load_at_size(image_path, width, height)
        image = Vips::Image.new_from_file(image_path).crop(0, 0, width, height)

        image = image.flatten background: [128, 255, 128] if image.has_alpha?

        image
      end

      def generate_simple_text(text, box, font, width, height, min_dpi, align=:low)
        text_image, meta = Vips::Image.text(
          text,
          font: font,
          width: width,
          height: height,
          align: align,
          autofit_dpi: 1
        )

        text_image = Vips::Image.text(
          text,
          font: font,
          width: width,
          height: height,
          align: align,
          dpi: min_dpi
        ) if meta["autofit_dpi"] > min_dpi

        # We use a black sizing box so that we can identify the black
        # pixels later as ones where the box image needs to show through
        sizing_box = Vips::Image.black(box.width, box.height)
        boxed_text = center_overlay(sizing_box, text_image)

        # At this point we have white text on a black background.
        # We replace the white pixels with black, and the black pixels
        # with pixels from the box image, leaving us with black text
        # on top of the box image
        boxed_text.bandand.ifthenelse([0,0,0], box, blend: true)
      end

      def center_overlay(lower_image, upper_image)
        lower_image.composite2(
          upper_image,
          :over,
          x: (lower_image.width - upper_image.width)/2,
          y: (lower_image.height - upper_image.height)/2
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
    end
  end
end
