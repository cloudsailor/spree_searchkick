module SpreeSearchkick
  module Spree
    module ShippingMethodCategoryDecorator
      def self.prepended(base)
        base.after_save :sync_country_shipping_category_mapping
        base.after_destroy :sync_country_shipping_category_mapping
      end

      def sync_country_shipping_category_mapping
        return if self.shipping_method.blank? || self.shipping_method.destroyed? || !self.shipping_method.persisted?

        country_ids = self.shipping_method.zones.map {|z| z.countries.map {|c| c.id } }.flatten.uniq
        ::Spree::Country.where(id: country_ids).each do |c|
          shipping_category_ids = c.zones.map do |z|
            z.shipping_methods.map do |sm|
              sm.shipping_categories.map {|sc| sc.id }
            end
          end.flatten.uniq

          ::SpreeSearchkick::Spree::ShippingCountry.add(c, shipping_category_ids)
        end

        ::SpreeSearchkick::Spree::ShippingCategoryCountry.add([self.shipping_category.id])
      end
    end
  end
end

::Spree::ShippingMethodZone.prepend ::SpreeSearchkick::Spree::ShippingMethodZoneDecorator
