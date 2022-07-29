class CreateSpreeShippingCategoryCountriesTable < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_shipping_category_countries do |t|
      t.references :shipping_category, type: :integer, index: {name: 'index_spree_shipping_category_countries_on_shipping_category_id'}, foreign_key: {to_table: :spree_shipping_categories}, null: false, unique: true
      t.text :countries, limit: 1024, null: false

      t.timestamps
    end
  end
end

