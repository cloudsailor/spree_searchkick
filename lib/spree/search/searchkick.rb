module Spree
  module Search
    class Searchkick < Spree::Core::Search::Base
      def retrieve_products(**args)
        @products =  defined?(args) ? base_elasticsearch(args) : base_elasticsearch
      end

      def base_elasticsearch(**args)
        curr_page = page || 1
        Spree::Product.search(
          keyword_query,
          fields: Spree::Product.search_fields,
          where: defined?(args) ? where_query(**args) : where_query,
          aggs: aggregations,
          smart_aggs: true,
          order: sorted,
          page: curr_page,
          per_page: per_page,
          includes: [
                  # :tax_category,
                  variants: [
                      {images: {attachment_attachment: :blob}}
                  ],
                  master: [
                      :prices,
                      {images: {attachment_attachment: :blob}}
                  ]
              ]
        )
      end

      def where_query(**args)
        where_query = {
          active: true,
          currency: current_currency,
          price: { not: nil },
        }

        if defined?(args)
          where_query = where_query.merge(args)
        end
        where_query[:taxon_ids] = taxon.id if taxon
        if @properties[:price]
          parts = @properties[:price].split(",")
          where_query[:price] = {gte: parts[0].to_f, lte: parts[1].to_f}
        end
        add_search_filters(where_query)
      end

      def keyword_query
        keywords.nil? || keywords.empty? ? "*" : keywords
      end

      def sorted
        order_params = {}
        order_params[:conversions] = :desc if conversions
        order_params[:price] = :desc if @properties[:sort_by] == 'price-high-to-low'
        order_params[:price] = :asc if @properties[:sort_by] == 'price-low-to-high'
        order_params[:created_at] = :desc if @properties[:sort_by] == 'newest-first'
        order_params
      end

      def aggregations
        fs = []

        aggregation_classes.each do |agg_class|
          agg_class.filterable.each do |record|
            fs << record.filter_name.to_sym
          end
        end
        fs
      end

      def aggregation_classes
        [
          Spree::Taxonomy, 
          Spree::Property, 
          Spree::OptionType
        ]
      end

      def add_search_filters(query)
        return query unless search
        search.each do |name, scope_attribute|
          query.merge!(Hash[name, scope_attribute])
        end
        query
      end

      def prepare(params)
        super
        @properties[:conversions] = params[:conversions]
      end
    end
  end
end
