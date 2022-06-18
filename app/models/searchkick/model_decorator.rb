module Searchkick
  module ModelDecorator
    class << self
      def searchkick_index(name: nil)
        index = name || class_variable_get(:@@searchkick_index)
        index = index.call if index.respond_to?(:call)
        index_cache = class_variable_get(:@@searchkick_index_cache)
        unless index_cache.has_key?(index)
          index_cache[index] = Searchkick::Index.new(index, searchkick_options)
          index_cache[index].ensure_alias
        end

        index_cache[index]
      end
    end
  end
end

::Searchkick::Model.prepend ::Searchkick::ModelDecorator