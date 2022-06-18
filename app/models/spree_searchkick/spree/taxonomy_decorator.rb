module SpreeSearchkick
  module Spree
    module TaxonomyDecorator
      def self.prepended(base)
        base.scope :filterable, -> { where(filterable: true) }
      end
      
      def filter_name
        "#{name.downcase}_ids"
      end
    end
  end
end

::Spree::Taxonomy.prepend(::SpreeSearchkick::Spree::TaxonomyDecorator)