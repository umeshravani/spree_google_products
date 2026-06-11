# Uncomment lines below to add your own custom business logic
# such as promotions, shipping methods, etc.
Rails.application.config.after_initialize do
  # Safely inject HTML partials ONLY if the Storefront is active
  if Spree.respond_to?(:storefront) && Spree.storefront.respond_to?(:partials)
    Spree.storefront.partials.head << 'spree_google_products/head'
  end
end
