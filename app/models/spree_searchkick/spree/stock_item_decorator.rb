module SpreeSearchkick
  module Spree
    module StockItemDecorator
      def self.prepended(base)
        base.reset_callbacks :touch
        base.reset_callbacks :save
        base.reset_callbacks :destroy

        base.after_commit :propagate
      end

      def propagate
        return if variant.blank?

        # variant.sync_inventory
      end
    end
  end
end

::Spree::StockItem.prepend ::SpreeSearchkick::Spree::StockItemDecorator
