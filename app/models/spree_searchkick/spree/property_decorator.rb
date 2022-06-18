module SpreeSearchkick
  module Spree
    module PropertyDecorator
      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }
      end

      def filter_name
        name.downcase.to_s
      end
    end
  end
end

::Spree::Property.prepend(::SpreeSearchkick::Spree::PropertyDecorator)
