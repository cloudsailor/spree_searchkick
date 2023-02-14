module SpreeSearchkick
  module Spree
    module VariantDecorator
      def self.prepended(base)
        base.has_one :inventory, class_name: '::SpreeSearchkick::Spree::Inventory', foreign_key: :inv_id, inverse_of: :variant, dependent: :destroy

        # base.after_save :sync_inventory
        # base.after_destroy :sync_inventory
        base.after_save :reindex_product
        base.after_destroy :reindex_product
      end

      def reindex_product
        # if self.new_record? || self.destroyed? || self.shipping_category_id_changed?
        self.product.reindex
        # end
      end
    end
  end
end

::Spree::Variant.prepend ::SpreeSearchkick::Spree::VariantDecorator