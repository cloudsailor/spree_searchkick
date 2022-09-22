module SpreeSearchkick
  module Spree
    module PropertyDecorator
      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }
      end

      def filter_param
        filter_name
      end

      def filter_name
        name.downcase.to_s
      end

      def filter_values
        pvs = []

        prop_vals = ::Spree::ProductProperty.select("value, count(*) as val_cnt").where(property_id: self.id).unscope(:order).group(:value)
        prop_vals.sort {|pv1, pv2| pv2.val_cnt <=> pv1.val_cnt }.each do |pv|
          if pv.val_cnt < 10
            next
          end

          if pv.value.size > 30
            next
          end

          if ['na', 'n/a', 'not applicable'].include?(pv.value.downcase)
            next
          end

          pvs << pv.value
        end

        pvs.first(10)
      end
    end
  end
end

::Spree::Property.prepend(::SpreeSearchkick::Spree::PropertyDecorator)
