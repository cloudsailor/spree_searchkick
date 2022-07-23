class CreateSpreeInventoryTable < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_inventories do |t|
      t.references :product, type: :integer, index: true, foreign_key: {to_table: :spree_products}, null: false
      t.references :variant, type: :integer, index: true, foreign_key: {to_table: :spree_variants}, null: false
      t.string :isin, index: true, null: false

      t.references :inv, type: :integer, index: true, foreign_key: {to_table: :spree_variants}, null: false
      t.references :vendor, type: :integer, index: true, foreign_key: {to_table: :spree_vendors}, null: false
      t.string :sku, index: true
      t.datetime :selling_at, null: false
      t.boolean :purchasable, index: true, null: false, default: false
      t.boolean :in_stock, index: true, null: false, default: false
      t.float :price, null: false
      t.string :currency, null: false
      t.integer :quantity, null: false, default: 0
      t.references :shipping_category, type: :integer, index: true, foreign_key: {to_table: :spree_shipping_categories}, null: false

      t.timestamps
    end
  end
end

