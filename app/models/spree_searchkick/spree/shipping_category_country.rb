module SpreeSearchkick
  module Spree
    class ShippingCategoryCountry < ::Spree::Base
      self.table_name = 'spree_shipping_category_countries'

      def self.countries_for_shipping_category(shipping_category_id)
        scc = self.find_by(shipping_category_id: shipping_category_id)
        scc.get_countries
      end

      def self.add(shipping_category_ids)
        ::Spree::ShippingCategory.where(id: shipping_category_ids).each do |sc|
          countries = sc.shipping_methods.map do |sm|
            sm.zones.map {|z| z.countries.map {|c| c.iso } }
          end.flatten.uniq

          begin
            scc = self.find_by(shipping_category_id: sc.id)
            if scc.blank?
              scc = self.new(shipping_category_id: sc.id)
              scc.countries = countries.join(',')
              scc.save

              return
            end

            cur_countries = scc.get_countries
            if countries != cur_countries
              scc.countries = countries.join(',')
              ::SyncProductCountryJob.perform_later(scc)
            end
          rescue ActiveRecord::RecordNotUnique => e
            Rails.logger.error e.message

            sleep 1
            retry
          end
        end
      end

      def get_countries
        if self.countries.blank?
          []
        else
          self.countries&.split(',') || []
        end
      end
    end
  end
end
