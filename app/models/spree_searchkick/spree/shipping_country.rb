module SpreeSearchkick
  module Spree
    class ShippingCountry < ::Spree::Base
      self.table_name = 'spree_shipping_countries'

      def self.shipping_category_ids_for_country(country)
        sc = self.find_by(country: country)
        if sc.blank?
          []
        else
          sc.shipping_category_ids&.split(',') || []
        end
      end

      def self.add(country, shipping_category_ids)
        code = country.iso

        begin
          sc = self.find_by(country: code)
          if sc.blank?
            sc = self.new(country: code)
          end
          sc.shipping_category_ids = shipping_category_ids.join(',')

          sc.save
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.error e.message

          sleep 1
          retry
        end
      end
    end
  end
end
