namespace :shipping_country do
  desc "Initialize shipping countries"
  task init: :environment do
    puts "Initializing shipping countries..."
    begin
      Spree::Country.all.each do |c|
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
    puts "Shipping country is initialized!"
  end
end