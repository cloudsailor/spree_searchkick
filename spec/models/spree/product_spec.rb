require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  describe 'searches' do
    let(:product) { create(:product) }

    it 'autocomplete by name' do
      keyword = product.name[0..6]
      Spree::Product.reindex
      expect(Spree::Product.autocomplete(keyword)).to eq([product.name.strip])
    end

    context 'products that are not yet available' do
      let(:product) { create(:product, available_on: nil) }

      it 'does not return them in autocomplete' do
        keyword = product.name[0..6]
        Spree::Product.reindex
        expect(Spree::Product.autocomplete(keyword)).to eq([])
      end
    end

    context 'products with no price' do
      let(:product) do
        create(:product).tap { |_| Spree::Price.update_all(amount: nil) }
      end

      it 'does not return them in autocomplete' do
        keyword = product.name[0..6]
        Spree::Product.reindex
        expect(Spree::Product.autocomplete(keyword)).to eq([])
      end
    end
  end

  describe '#search_data' do
    let(:property) { create(:property, name: 'Length', filterable: true) }
    let(:taxonomy) { create(:taxonomy, name: 'Categories') }
    let!(:taxon) { create(:taxon, name: 'T-shirts', taxonomy: taxonomy) }
    let!(:option_type) { create(:option_type, name: 'Size', filterable: true) }
    let(:option_value) { create(:option_value, option_type: option_type, name: 'xs', presentation: 'XS')}
    let(:property_value) { '10in' }

    let(:product) do
      create(
        :product_in_stock,
        name: 'Some Product', 
        description: 'Example description',
        sku: 'SKU100',
        price: 350.90
      )
    end
    let(:data) do
      {
        id: product.id,
        name: 'Some Product',
        description: 'Example description',
        active: true,
        price: 350.90.to_d,
        currency: 'USD',
        in_stock: true,
        total_on_hand: 10,
        skus: ['SKU100', 'SKU200'],
        slug: product.slug,
        created_at: product.created_at,
        updated_at: product.updated_at,
        properties: [{ id: property.id, name: property.name, value: property_value}],
        property_ids: [property.id],
        property_names: ['Length'],
        taxon_ids: [taxonomy.root.id, taxon.id],
        taxon_names: ['Categories', 'T-shirts'],
        option_type_ids: [option_type.id],
        option_type_names: [option_type.name],
        option_value_ids: [option_value.id],
        conversions: 0,
        length: '10in',
        size: ['xs']
      }
    end

    before do
      product.option_types << option_type
      product.set_property(property.name, property_value)
      product.taxons << taxon
      variant = create(:variant, sku: 'SKU200', product: product, option_values: [option_value])
      variant.stock_items.first.set_count_on_hand(10)
      product.reload
    end

    it 'contains all required data for ES' do
      expect(product.search_data.symbolize_keys).to eq data
    end
  end
end
