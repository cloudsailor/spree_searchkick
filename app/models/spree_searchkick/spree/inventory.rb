module Spree::Searchkick
  module Spree
    class Inventory < Spree::Base
      self.table_name = 'spree_inventories'

      belongs_to :variant, class_name: 'Spree::Variant', foreign_key: 'inv_id', inverse_of: :inventory
    end
  end
end
