module SpreeSearchkick
  module Spree
    module OptionTypeDecorator
      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }
      end

      def filter_name
        name.downcase.to_s
      end
    end
  end
end

::Spree::OptionType.prepend(::SpreeSearchkick::Spree::OptionTypeDecorator)
