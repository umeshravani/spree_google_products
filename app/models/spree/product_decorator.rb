module Spree
    module ProductDecorator
      def self.prepended(base)
        base.has_one :google_product_attribute, class_name: 'Spree::GoogleProductAttribute', dependent: :destroy
        base.accepts_nested_attributes_for :google_product_attribute, allow_destroy: true
        #base.after_initialize :ensure_google_attribute
        base.after_commit :sync_to_google, on: [:create, :update]
      end
  
      private
  
      def ensure_google_attribute
        build_google_product_attribute if google_product_attribute.nil?
      end
  
      def sync_to_google
        Spree::GoogleShopping::SyncProductJob.perform_later(self.id)
      end

      def sync_to_google_shopping
        credential = Spree::Store.default.google_credential
        return unless credential&.ready_for_sync?
        return if saved_changes.keys.include?('google_product_attribute_updated_at')
        Spree::GoogleShopping::SyncProductJob.perform_later(self.id)
      end
    end
  end

  Spree::Product.prepend(Spree::ProductDecorator)
