class AddFiltrableToSpreeTaxonomies < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_taxonomies, :filterable, :boolean unless column_exists?(:spree_taxonomies, :filterable)
  end
end
