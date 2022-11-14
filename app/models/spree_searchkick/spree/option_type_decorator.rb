module SpreeSearchkick
  module Spree
    module OptionTypeDecorator
      class_variable_set :@@filterable_option_types, nil

      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }

        base.instance_eval do
          def filterable_option_types
            @@filterable_option_types ||= if ::Spree::OptionType.respond_to?(:fetch_all_by)
              ::Spree::OptionType.fetch_all_by(filterable: true)
            else
              ::Spree::OptionType.filterable
            end
          end
        end
      end

      def filter_name
        name.downcase.to_s
      end
    end
  end
end

::Spree::OptionType.prepend(::SpreeSearchkick::Spree::OptionTypeDecorator)
