Rails.application.config.to_prepare do
  if defined?(Spree)
    ability_class = "Spree::Ability".safe_constantize

    if ability_class
      if ability_class.respond_to?(:register_ability)
        # Pre-Spree 5.5 Legacy Registration
        ability_class.register_ability(SpreeGoogleProducts::Ability)
      else
        # Spree 5.5+ Safe Initialization Merge
        ability_class.prepend(Module.new do
          def initialize(*args, **kwargs)
            # 1. Let Spree 5.5 load ALL core Admin Permission Sets first
            super
            # 2. Prevent recursive subclass loading
            if self.class == Spree::Ability
              # 3. Extract the single user argument the legacy extension expects
              user = args.first 
              merge(SpreeGoogleProducts::Ability.new(user))
            end
          end
        end)
      end
    end
  end
end

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
end
