module Spree::OrderDecorator
  def self.prepended(base)
    base.state_machine.after_transition to: :complete, do: :reindex_order_products
    base.searchkick(
      callbacks: :async,
      word_start: [:name],
      settings: { number_of_replicas: 0 },
      index_prefix: ENV['SITE_NAME'],
      merge_mappings: true,
      mappings: {
        properties: {
          properties: {
            type: 'nested'
          }
        }
      }
    ) unless base.respond_to?(:searchkick_index)

    def base.autocomplete_fields
      [:number]
    end

    def base.search_fields
      [:number, :email, :skus, :firstname, :lastname, :state, :payment_state, :shipment_state, :promotions_ids, :store_id ,:channel]
    end

    def base.add_searchkick_option(option)
      base.class_variable_set(:@@searchkick_options, base.searchkick_options.deep_merge(option))
    end

  end

  def search_data
    all_variants = variants.pluck(:id, :sku)
    firstname = shipping_address&.firstname
    lastname = shipping_address&.lastname
    json = {
      id: id,
      number: number,
      email: email,
      skus: all_variants.map(&:last),
      firstname: firstname,
      lastname: lastname,
      created_at: created_at,
      state: state,
      payment_state: payment_state,
      shipment_state: shipment_state,
      promotions_ids: promotions.pluck(:id),
      store_id: store_id,
      channel: channel,
      completed_at: completed_at,
      considered_risky: considered_risky,
      approver_id: approver_id,
      approved_at: approved_at,
      group_buy: group_buy
    }

    json
  end

  def index_data
    {}
  end

  def reindex_order_products
    return unless complete?
    products.map(&:reindex)
  end
end

Spree::Order.prepend(Spree::OrderDecorator)