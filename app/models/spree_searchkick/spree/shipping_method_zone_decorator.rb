module SpreeSearchkick
  module Spree
    module ShippingMethodZoneDecorator
      def self.prepended(base)
        base.after_save :sync_country_shipping_category_mapping
        base.after_destroy :sync_country_shipping_category_mapping
      end

      def sync_country_shipping_category_mapping
        return if self.zone.blank? || self.zone.destroyed? || !self.zone.persisted?

        self.zone.countries.each do |c|
          shipping_category_ids = c.zones.map do |z|
            z.shipping_methods.map do |sm|
              sm.shipping_categories.map {|sc| sc.id }
            end
          end.flatten.uniq

          ::SpreeSearchkick::Spree::ShippingCountry.add(c, shipping_category_ids)
        end

        shipping_category_ids = self.shipping_method&.shipping_categories&.map {|sc| sc.id }&.uniq
        return if shipping_category_ids.blank?

        ::SpreeSearchkick::Spree::ShippingCategoryCountry.add(shipping_category_ids)
      end
    end
  end
end

::Spree::ShippingMethodZone.prepend ::SpreeSearchkick::Spree::ShippingMethodZoneDecorator
