module Spree
  module Search
    class Searchkick < Spree::Core::Search::Base

      require 'date'

      def multi_keys_search(value, page, per_page)
        multi_search_keys = ['number', 'email', 'firstname', 'lastname', 'skus']
        orders = []
        multi_search_keys.each do |key|
          orders = order_base_elasticsearch(@order_args.merge({key => value}), page, per_page)
          if orders.present?
            break
          end
        end
        orders
      end

      def retrieve_orders(args={}, page, per_page)
        @order_args = {:approver_id => {_not: nil}}
        params_before = {
          :completed_at => "1",
          :considered_risky => "1",
          :group_buy => "1",
          :approver_id => "1",
        }
        params_after = {
          :completed_at => {_not: nil},
          :considered_risky => true,
          :group_buy => true,
          :approver_id => {},
        }

        compare_keys = [:completed_at_lt, :completed_at_gt]

        args.each do |key, value|
          if (value&.present?) && (key != :number_cont) && (not compare_keys.include?(key))
            @order_args = @order_args.merge({key => value})
          end
        end

        compare_keys.each do |key|
          if args[key].present?
            if @order_args.key?(:completed_at) && @order_args[:completed_at] != "1"
              @order_args[:completed_at] = @order_args[:completed_at].merge({key[-2,2].to_sym => args[key]})
            else
              @order_args[:completed_at] = {}
              @order_args[:completed_at][key[-2,2].to_sym] = args[key]
            end
          end
        end

        params_before.each do |key, value|
          if @order_args[key] == value
            @order_args[key] = params_after[key]
          end
        end
 
        if args[:number_cont].present?
          @orders = multi_keys_search(args[:number_cont], page, per_page)
        else
          @orders =  order_base_elasticsearch(@order_args, page, per_page)
        end

      end

      def order_base_elasticsearch(args={}, page, per_page)
        curr_page = page || 1
        Spree::Order.search(
          keyword_query,
          where: order_where_query(args),
          aggs: aggregations,
          smart_aggs: true,
          order: {created_at: :desc},
          page: curr_page,
          per_page: per_page
        )
      end

      def retrieve_products(args={})
        @products = base_elasticsearch(args)
      end

      def base_elasticsearch(args={})
        curr_page = page || 1
        Spree::Product.search(
          keyword_query,
          fields: Spree::Product.search_fields,
          where: where_query(args),
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

      def order_where_query(args={})
        where_query = {
        }
        where_query = where_query.merge(args)
        add_search_filters(where_query)
      end

      def where_query(args={})
        where_query = {
          active: true,
          currency: current_currency,
          price: { not: nil },
        }
        where_query = where_query.merge(args)
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
