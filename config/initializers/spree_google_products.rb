# 1. Handle Class Reloading Safely for Abilities (Spree 5.5+ Production-Proof)
Rails.application.config.to_prepare do
  if defined?(Spree)
    # safe_constantize forces Zeitwerk to load the class safely during production boot
    ability_class = "Spree::Ability".safe_constantize

    if ability_class
      if ability_class.respond_to?(:register_ability)
        # Pre-Spree 5.5 Legacy Registration
        ability_class.register_ability(SpreeGoogleProducts::Ability)
      else
        # Spree 5.5+ Native Extension Registry
        ability_class.prepend(Module.new do
          def abilities_to_register
            base_abilities = defined?(super) ? super : []
            base_abilities | [SpreeGoogleProducts::Ability]
          end
        end)
      end
    end
  end
end

# 2. Handle Boot-time UI Configurations
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
