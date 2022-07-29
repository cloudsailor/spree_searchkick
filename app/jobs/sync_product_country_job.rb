class SyncProductCountryJob < ApplicationJob
  queue_as :searchkick

  def perform(scc)
    product_ids = ::SpreeSearchkick::Spree::Inventory.where(shipping_category_id: scc.shipping_category_id).group(:product_id).pluck(:product_id)
    # if product_ids.count > 10000
    #   Rails.logger.error("Trying to update shipping category #{scc.shipping_category_id} countries with more than 10000 products, skip!")
    #   return
    # end

    ::Spree::Product.where(id: product_ids).find_in_batches.each do |batch|
      batch.each {|product| product.reindex }
    end
  end

end
