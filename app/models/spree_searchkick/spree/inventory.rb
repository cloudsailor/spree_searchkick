module SpreeSearchkick
  module Spree
    class Inventory < ::Spree::Base
      self.table_name = 'spree_inventories'

      belongs_to :variant, class_name: 'Spree::Variant', foreign_key: 'inv_id', inverse_of: :inventory
      belongs_to :product, class_name: 'Spree::Product', foreign_key: 'product_id', inverse_of: :inventories

      after_commit :reindex_product

      def reindex_product
        product&.reindex
      end
    end
  end
end
