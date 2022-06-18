module Searchkick
  module IndexDecorator
    unless method_defined?(:ensure_alias)
      def ensure_alias
        while !alias_exists? do
          delete if exists?

          latest_index_name = all_indices.sort.last
          if latest_index_name.nil?
            replace_indice
          else
            promote(latest_index_name)
          end
        end
        clean_indices
      end
    end

    unless method_defined?(:replace_indice)
      def replace_indice(index_options: nil)
        index = create_index
        if alias_exists?
          promote(index.name)
        else
          delete if exists?
          promote(index.name)
        end
        clean_indices

        current_indices = all_indices
        current_indices.size == 1 && current_indices.include?(index.name)
      end
    end

    unless method_defined?(:full_index)
      def full_index(relation, method_name, scoped:, **options)
        refresh = options.fetch(:refresh, !scoped)
        options.delete(:refresh)

        indice_name = options.delete(:index_name)
        indice_name ||= all_indices.sort.last
        if indice_name.nil?
          reindex relation, method_name, scoped: scoped, full: true, scope: nil, **options
        else
          index = Searchkick::Index.new(indice_name, @options)
          index.import_scope(relation)
          index.refresh if refresh
        end
      end
    end
  end
end

::Searchkick::Index.prepend ::Searchkick::IndexDecorator