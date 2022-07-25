class ChangeSpreeInventoriesInvIdIndexToUniq < ::SpreeExtension::Migration[6.0]
  def up
    remove_foreign_key :spree_inventories, column: :inv_id
    remove_index :spree_inventories, column: :inv_id, name: 'index_spree_inventories_on_inv_id'

    add_index :spree_inventories, :inv_id, name: 'index_spree_inventories_on_inv_id', unique: true
    add_foreign_key :spree_inventories, :spree_variants, column: :inv_id
  end

  def down
    remove_foreign_key :spree_inventories, column: :inv_id
    remove_index :spree_inventories, column: :inv_id, name: 'index_spree_inventories_on_inv_id'

    add_index :spree_inventories, :inv_id, name: 'index_spree_inventories_on_inv_id'
    add_foreign_key :spree_inventories, :spree_variants, column: :inv_id
  end
end
