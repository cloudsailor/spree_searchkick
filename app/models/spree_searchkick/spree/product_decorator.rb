module SpreeSearchkick
  module Spree
    module ProductDecorator
      def self.prepended(base)
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

        base.scope :search_import, lambda {
          includes(
            :option_types,
            :variants_including_master,
            taxons: :taxonomy,
            master: :default_price,
            product_properties: :property,
            variants: :option_values
          )
        }

        base.skip_callback :commit, :after, :reindex, raise: false
        base.after_save :reindex, if: -> { ::Searchkick.callbacks?(default: :async) }
        base.after_destroy :reindex, if: -> { ::Searchkick.callbacks?(default: :async) }

        def base.autocomplete_fields
          [:name]
        end

        def base.search_fields
          [:name]
        end

        def base.filter_fields
          fields = [:price, :brand, :in_stock, :conversions, :has_image, :total_on_hand, :purchasable, :taxon_ids]
          fields.concat(::Spree::Property.filterable.map {|prop| prop.filter_name })
          fields.concat(::Spree::OptionType.filterable.map {|ot| ot.filter_name })

          fields.compact.uniq
        end

        def base.replace_indice
          ::Spree::Product.searchkick_index.replace_indice

          begin
            ::Spree::Product.includes(:representation).find_in_batches.each do |batch|
              batch.each do |product|
                product.reindex(nil, mode: :inline)
              end
            end
          rescue ActiveRecord::ActiveRecordError => e
            ActiveRecord::Base.connection.reconnect!
            sleep 3

            retry
          end
        end

        def base.autocomplete(keywords)
          if keywords
            Spree::Product.search(
              keywords,
              fields: autocomplete_fields,
              match: :word_start,
              limit: 10,
              load: false,
              misspellings: { below: 3 },
              where: search_where,
            ).map(&:name).map(&:strip).uniq
          else
            Spree::Product.search(
              "*",
              fields: autocomplete_fields,
              load: false,
              misspellings: { below: 3 },
              where: search_where,
            ).map(&:name).map(&:strip)
          end
        end

        def base.search_where
          {
            active: true,
            price: { gt: 0 },
          }
        end

        # Searchkick can't be reinitialized, this method allow to change options without it
        # ex add_searchkick_option { settings: { "index.mapping.total_fields.limit": 2000 } }
        def base.add_searchkick_option(option)
          base.class_variable_set(:@@searchkick_options, base.searchkick_options.deep_merge(option))
        end
      end

      def search_data
        if defined?(::Spree::Representation)
          json = search_data_representable
        else
          all_variants = variants_including_master.pluck(:id, :sku)

          all_taxons = taxons.flat_map { |t| t.self_and_ancestors.pluck(:id, :name) }.uniq

          quantity = total_on_hand
          if quantity == Float::INFINITY
            quantity = 100
          end

          json = {
            id: id,
            name: name,
            slug: slug,
            description: description,
            active: available?,
            in_stock: in_stock?,
            created_at: created_at,
            updated_at: updated_at,
            price: price,
            currency: currency,
            conversions: orders.complete.count,
            taxon_ids: all_taxons.map(&:first),
            taxon_names: all_taxons.map(&:last),
            skus: all_variants.map(&:last),
            total_on_hand: quantity,
            has_image: images.count > 0,
            purchasable: purchasable?
          }

          json.merge!(option_types_for_es_index(all_variants))
          json.merge!(properties_for_es_index)
        end

        json.merge!(index_data)

        json
      end

      def search_data_representable
        taxons = {}
        presenter[:taxons].each do |t_path|
          t_path.each do |taxon|
            unless taxons.has_key?(taxon[:id])
              taxons[taxon[:id]] = taxon
            end
          end
        end
        properties = presenter[:properties]&.select {|prop| !prop[:value].blank? }
        if properties.nil?
          properties = []
        end

        quantity = presenter[:total_on_hand]
        if quantity == Float::INFINITY
          quantity = 100
        end

        json = {
          id: presenter[:id],
          name: presenter[:name],
          slug: presenter[:slug],
          description: presenter[:description],
          active: presenter[:available],
          in_stock: presenter[:in_stock],
          created_at: presenter[:created_at],
          updated_at: presenter[:updated_at],
          price: presenter[:price].blank? ? 0 : presenter[:price].to_f.round(2),
          currency: presenter[:currency],
          conversions: presenter[:conversions],
          taxon_ids: taxons.values.map {|t| t[:id] },
          taxon_names: taxons.values.map {|t| t[:name] },
          skus: presenter[:variants].map {|v| v[:sku] },
          total_on_hand: quantity,
          has_image: presenter[:images].blank? ? false : true,
          purchasable: presenter[:purchasable],
          property_ids: properties.map {|prop| prop[:id] },
          property_names: properties.map {|prop| prop[:name] },
          properties: properties.map {|prop| { id: prop[:id], name: prop[:name], value: prop[:value] } }
        }

        properties.each do |prop|
          json.merge!(Hash[prop[:name].downcase, prop[:value].downcase])
        end

        json
      end

      def option_types_for_es_index(all_variants)
        filterable_option_types = option_types.filterable.pluck(:id, :name)
        option_value_ids = ::Spree::OptionValueVariant.where(variant_id: all_variants.map(&:first)).pluck(:option_value_id).uniq
        option_values = ::Spree::OptionValue.where(
          id: option_value_ids, 
          option_type_id: filterable_option_types.map(&:first)
        ).pluck(:option_type_id, :name)

        json = {
          option_type_ids: filterable_option_types.map(&:first),
          option_type_names: filterable_option_types.map(&:last),
          option_value_ids: option_value_ids
        }

        filterable_option_types.each do |option_type|
          values = option_values.find_all { |ov| ov.first == option_type.first }.map(&:last).uniq.compact.each(&:downcase)

          json.merge!(Hash[option_type.last.downcase, values]) if values.present?
        end

        json
      end

      def properties_for_es_index
        filterable_properties = properties.filterable.pluck(:id, :name)
        properties_values = product_properties.where(property_id: filterable_properties.map(&:first)).pluck(:property_id, :value)

        filterable_properties = filterable_properties.map do |prop|
          {
            id: prop.first,
            name: prop.last,
            value: properties_values.find { |pv| pv.first == prop.first }&.last
          }
        end

        json = { property_ids: filterable_properties.map { |p| p[:id] } }
        json.merge!(property_names: filterable_properties.map { |p| p[:name] })
        json.merge!(properties: filterable_properties)

        filterable_properties.each do |prop|
          json.merge!(Hash[prop[:name].downcase, prop[:value].downcase]) if prop[:value].present?
        end

        json
      end

      def index_data
        {}
      end
    end
  end
end

::Spree::Product.prepend(::SpreeSearchkick::Spree::ProductDecorator)
