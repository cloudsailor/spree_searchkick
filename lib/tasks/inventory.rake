namespace :inventory do
  desc "Initialize inventory"
  task sync: :environment do
    puts "Sync inventory..."
    begin
      ::Spree::Variant.find_in_batches do |batch|
        batch.each {|v| ::SyncInventoryJob.perform_later(v) }
      end
    rescue ::ActiveRecord::ActiveRecordError => e
      ::ActiveRecord::Base.connection.reconnect!
      sleep 3

      retry
    end
    puts "Inventories is synced!"
  end
end