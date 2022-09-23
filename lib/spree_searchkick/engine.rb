module SpreeSearchkick
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_searchkick'

    config.autoload_paths += %W[#{config.root}/lib]

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/models/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      if ::SpreeSearchkick::Engine.frontend_available?
        Dir.glob(File.join(File.dirname(__FILE__), '../../app/controllers/**/*_decorator*.rb')) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end

      Dir.glob(File.join(File.dirname(__FILE__), '../../app/helpers/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      ::Spree::Config.searcher_class = ::Spree::Search::Searchkick

      unless ::Spree::Frontend::Config.additional_filters_partials.include?(:property)
        ::Spree::Frontend::Config.additional_filters_partials = ::Spree::Frontend::Config.additional_filters_partials.concat([:property])
      end
    end

    config.to_prepare &method(:activate).to_proc

    def self.frontend_available?
      @@frontend_available ||= ::Rails::Engine.subclasses.map(&:instance).map{ |e| e.class.to_s }.include?('Spree::Frontend::Engine')
    end
  end
end
