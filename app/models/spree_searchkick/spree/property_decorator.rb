module SpreeSearchkick
  module Spree
    module PropertyDecorator
      class_variable_set :@@property_values, nil

      def self.prepended(base)
        # base.extend(ClassMethods)

        base.scope :filterable, -> { where(filterable: true) }

        base.instance_eval do
          def property_values
            return @@property_values if @@property_values.present?

            pvs = {}
            product_properties = ::Spree::ProductProperty.where(property_id: ::Spree::Property.filterable.map {|p| p.id }).unscope(:order)
            product_properties.each do |pp|
              if ['na', 'n/a', 'not applicable'].include?(pp.value.downcase)
                next
              end

              k = pp.property_id
              pvs[k] = {} unless pvs.has_key?(k)

              v = pp.value
              if pvs[k].has_key?(v)
                pvs[k][v] += 1
              else
                pvs[k][v] = 1
              end
            end

            @@property_values = pvs
          end

          def refresh_property_values
            @@property_values = nil
            self.property_values
          end
        end
      end

      def filter_param
        filter_name
      end

      def filter_name
        name.downcase.to_s
      end

      def filter_values
        return [] unless self.class.property_values.has_key?(self.id)

        pvs = []
        self.class.property_values[self.id].sort {|pv1, pv2| pv2[1] <=> pv1[1] }.each do |pv_val, pv_val_cnt|
          if pv_val_cnt < 10
            next
          end

          if pv_val.size > 30
            next
          end

          pvs << pv_val
        end

        pvs.first(10)

        # pvs = []

        # prop_vals = ::Spree::ProductProperty.select("value, count(*) as val_cnt").where(property_id: self.id).unscope(:order).group(:value)
        # prop_vals.sort {|pv1, pv2| pv2.val_cnt <=> pv1.val_cnt }.each do |pv|
        #   if pv.val_cnt < 10
        #     next
        #   end

        #   if pv.value.size > 30
        #     next
        #   end

        #   if ['na', 'n/a', 'not applicable'].include?(pv.value.downcase)
        #     next
        #   end

        #   pvs << pv.value
        # end

        # pvs.first(10)
      end
    end
  end
end

::Spree::Property.prepend(::SpreeSearchkick::Spree::PropertyDecorator)
