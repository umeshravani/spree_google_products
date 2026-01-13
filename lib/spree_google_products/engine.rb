module SpreeGoogleProducts
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_google_products'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree_google_products.environment', before: :load_config_initializers do |_app|
      SpreeGoogleProducts::Config = SpreeGoogleProducts::Configuration.new
    end

    initializer 'spree_google_products.assets' do |app|
      app.config.assets.paths << root.join('app/assets/images')
    end

    initializer 'spree_google_products.importmap', before: 'importmap' do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join('config/importmap.rb')
        app.config.importmap.cache_sweepers << root.join('app/javascript')
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
