module SpreeSearchkick
  module Spree
    module PropertyDecorator
      class_variable_set :@@property_values, nil

      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }

        base.instance_eval do
          def filterable_properties
            if ::Spree::Property.respond_to?(:fetch_all_by)
              ::Spree::Property.fetch_all_by(filterable: true)
            else
              ::Spree::Property.filterable
            end
          end

          def filterable_property_values
            return @@property_values if @@property_values.present?

            filterable_product_properties = ::Spree::ProductProperty.where(property_id: filterable_properties.map {|p| p.id }).unscope(:order)

            pvs = {}
            filterable_product_properties.each do |pp|
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
        end
      end

      def filter_param
        filter_name
      end

      def filter_name
        name.downcase.to_s
      end

      def filter_values
        return [] unless self.class.filterable_property_values.has_key?(self.id)

        pvs = []
        self.class.filterable_property_values[self.id].sort {|pv1, pv2| pv2[1] <=> pv1[1] }.each do |pv_val, pv_val_cnt|
          if pv_val_cnt < 10
            next
          end

          if pv_val.size > 30
            next
          end

          pvs << pv_val
        end

        pvs.first(10)
      end
    end
  end
end

::Spree::Property.prepend(::SpreeSearchkick::Spree::PropertyDecorator)
