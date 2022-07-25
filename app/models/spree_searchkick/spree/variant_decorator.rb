module SpreeSearchkick
  module Spree
    module VariantDecorator
      def self.prepended(base)
        base.has_one :inventory, class_name: 'Spree::Inventory', foreign_key: :inv_id, inverse_of: :inventory, dependent: :destroy

        base.after_save :sync_inventory
        base.after_destroy :sync_inventory
      end

      def sync_inventory
        attrs = {
          product_id: product_id,
          variant_id: parent_id || self.id,
          isin: isin,
          inv_id: self.id,
          vendor_id: vendor_id,
          sku: sku,
          selling_at: created_at,
          purchasable: purchasable?,
          in_stock: in_stock?,
          price: price,
          currency: currency,
          shipping_category_id: shipping_category_id
        }
        begin
          if inventory.blank?
            ::Spree::Inventory.create(attrs)
          else
            attrs.delete(:inv_id)
            inventory.update(attrs)
          end
        rescue ActiveRecord::RecordNotUnique
        end
      end
    end
  end
end

::Spree::Variant.prepend ::SpreeSearchkick::Spree::VariantDecorator