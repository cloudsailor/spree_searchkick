module SpreeSearchkick
  class ReindexWhenZoneChangeJob < ApplicationJob
    queue_as :searchkick

    def perform(shipping_method_id)
      if shipping_method_id.present?
        shipping_method = ::Spree::ShippingMethod.find(shipping_method_id)
        shipping_method.shipping_categories.includes({ master_variants: :product }).each do |shipping_category|
          shipping_category.master_variants.find_each do |v|
            v.product.reindex
          end
        end
      end
    end

  end
end
