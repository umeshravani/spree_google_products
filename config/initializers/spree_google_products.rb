Rails.application.config.after_initialize do
  if Spree.respond_to?(:admin) && Spree.admin.respond_to?(:navigation)
    sidebar = Spree.admin.navigation.sidebar
    sidebar.add :google_shopping, 
      label: 'Google Shopping', 
      icon: 'brand-google', 
      url: :admin_google_shopping_dashboard_path, 
      position: 85
    sidebar.add :google_dashboard, 
      parent: :google_shopping, 
      label: 'Dashboard', 
      url: :admin_google_shopping_dashboard_path, 
      active: -> { params[:controller].include?('google_shopping/dashboard') }
    sidebar.add :google_products, 
      parent: :google_shopping, 
      label: 'Products', 
      url: :admin_google_shopping_products_path, 
      active: -> { params[:controller].include?('google_shopping/products') }
    sidebar.add :google_settings, 
      parent: :google_shopping, 
      label: :settings, 
      url: :edit_admin_google_merchant_settings_path, 
      active: -> { controller_name == 'google_merchant_settings' }
  end
  
  if defined?(Spree::Ability) && defined?(SpreeGoogleProducts::Ability)
    if Spree::Ability.respond_to?(:register_ability)
      # Target: Spree 5.4
      Spree::Ability.register_ability(SpreeGoogleProducts::Ability)
    else
      # Target: Spree 5.5+
      Spree::Ability.prepend(Module.new do
        def initialize(*args, **kwargs)
          super
          # Guard clause prevents recursive loading inside the subclasses
          if self.class == Spree::Ability
            merge(SpreeGoogleProducts::Ability.new(*args, **kwargs))
          end
        end
      end)
    end
  end
end
