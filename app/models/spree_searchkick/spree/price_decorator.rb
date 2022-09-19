module SpreeSearchkick
  module Spree
    module PriceDecorator
      def self.prepended(base)
        base.reset_callbacks :touch
        base.reset_callbacks :save

        base.after_save :propagate
        base.after_destroy :propagate
      end

      def propagate
        return if variant.blank?

        # variant.sync_inventory
      end
    end
  end
end

::Spree::Price.prepend ::SpreeSearchkick::Spree::PriceDecorator
