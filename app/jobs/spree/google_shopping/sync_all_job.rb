module Spree
  module GoogleShopping
    class SyncAllJob < SpreeGoogleProducts::BaseJob
      
      def perform
        credential = Spree::Store.default.google_credential
        return unless credential&.active?
          
        Spree::Product.active.find_each do |product|
          Spree::GoogleShopping::SyncProductJob.perform_later(product.id)
        end
        
        Rails.logger.info "GOOGLE: Queued sync for #{Spree::Product.active.count} products."
      end
    end
  end
end
