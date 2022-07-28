module SpreeSearchkick
  module Spree
    module ZoneMemberDecorator
      def self.prepended(base)
        base.after_save :sync_country_shipping_category_mapping
        base.after_destroy :sync_country_shipping_category_mapping
      end

      def sync_country_shipping_category_mapping
        return unless self.zoneable.is_a?(::Spree::Country)

        shipping_category_ids = self.zoneable.zones.map do |z|
          z.shipping_methods.map do |sm|
            sm.shipping_categories.map {|sc| sc.id }
          end
        end.flatten.uniq

        ::SpreeSearchkick::Spree::ShippingCountry.add(self.zoneable, shipping_category_ids)
      end
    end
  end
end

::Spree::ZoneMember.prepend ::SpreeSearchkick::Spree::ZoneMemberDecorator
