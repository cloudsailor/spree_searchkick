class AddFilterableToSpreeProperty < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_properties, :filterable, :boolean unless column_exists?(:spree_properties, :filterable)
  end
end
