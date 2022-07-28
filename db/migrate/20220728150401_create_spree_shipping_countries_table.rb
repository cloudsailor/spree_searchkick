class CreateSpreeShippingCountriesTable < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_shipping_countries do |t|
      t.string :country, index: true, null: false, unique: true
      t.text :shipping_category_ids, null: false

      t.timestamps
    end
  end
end

