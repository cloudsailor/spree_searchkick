namespace :shipping do
  desc "Initialize shipping and countries mapping"
  task init: :environment do
    puts "Initializing shipping and countries mapping..."
    begin
      ::Spree::Country.all.each do |c|
        shipping_category_ids = c.zones.map do |z|
          z.shipping_methods.map do |sm|
            sm.shipping_categories.map {|sc| sc.id }
          end
        end.flatten.uniq

        ::SpreeSearchkick::Spree::ShippingCountry.add(c, shipping_category_ids)
      end
    rescue ::ActiveRecord::ActiveRecordError => e
      ::ActiveRecord::Base.connection.reconnect!
      sleep 3

      retry
    end

    begin
      shipping_category_ids = ::Spree::ShippingCategory.all.map {|sc| sc.id }
      ::SpreeSearchkick::Spree::ShippingCategoryCountry.add(shipping_category_ids)
    rescue ::ActiveRecord::ActiveRecordError => e
      ::ActiveRecord::Base.connection.reconnect!
      sleep 3

      retry
    end
    puts "Shipping and countries mapping is initialized!"
  end
end