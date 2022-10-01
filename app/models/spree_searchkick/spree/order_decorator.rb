module SpreeSearchkick
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.state_machine.after_transition to: :complete, do: :reindex_order_products
      end

      def reindex_order_products
        return unless complete?

        if ::ActiveRecord::Base.connection.column_exists?(:spree_products, :conversions)
          products.each {|product| product.update_column(:conversions, product.orders.complete.count) }
        end

        products.map(&:reindex)
      end
    end
  end
end

::Spree::Order.prepend(::SpreeSearchkick::Spree::OrderDecorator)