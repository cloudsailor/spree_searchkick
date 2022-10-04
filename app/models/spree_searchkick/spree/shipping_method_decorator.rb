module SpreeSearchkick
  module Spree
    module ShippingMethodDecorator
      def self.prepended(base)

      end

      def after_add_for_zones_hook(zone)
        super(zone)
        SpreeSearchkick::ReindexWhenZoneChangeJob.perform_later(self.id)
      end

      def after_remove_for_zones_hook(zone)
        super(zone)
        SpreeSearchkick::ReindexWhenZoneChangeJob.perform_later(self.id)
      end

      def after_add_for_shipping_categories_hook(shipping_category)
        super(shipping_category)
        category_change_reindex_handler(shipping_category)
      end

      def after_remove_for_shipping_categories_hook(shipping_category)
        super(shipping_category)
        category_change_reindex_handler(shipping_category)
      end

      def category_change_reindex_handler(shipping_category)
        category_country_codes = shipping_category.ship_to_country_codes
        method_country_codes = self.ship_to_country_codes
        if (method_country_codes & category_country_codes) != method_country_codes
          shipping_category.master_variants.includes(:product).find_each { |v| v.product.reindex }
        end
      end
    end
  end
end

::Spree::ShippingMethod.prepend SpreeSearchkick::Spree::ShippingMethodDecorator