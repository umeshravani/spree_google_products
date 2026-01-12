module Spree
  module GoogleShopping
    class SyncProductJob < SpreeGoogleProducts::BaseJob
      # queue_as :default

      retry_on ::Google::Apis::ClientError, wait: :exponentially_longer, attempts: 5 do |job, error|
        msg = error.message.downcase
        msg.include?('quota') || msg.include?('limit') || msg.include?('too many requests')
      end

      retry_on ::Google::Apis::ServerError, wait: :exponentially_longer, attempts: 3

      def perform(product_id)

        product = Spree::Product.find_by(id: product_id)
        unless product
          Rails.logger.error "GOOGLE SYNC JOB: Product ID #{product_id} not found."
          return
        end

        credential = Spree::Store.default.google_credential
        unless credential&.active?
          Rails.logger.warn "GOOGLE SYNC JOB: Credential missing or inactive. Aborting."
          return
        end

        Rails.logger.info "GOOGLE SYNC JOB: Starting sync for Product '#{product.name}' (ID: #{product.id})..."
        
        begin

          service = Spree::GoogleShopping::ContentService.new(credential)
          service.push_product(product)

          Rails.logger.info "GOOGLE SYNC JOB: ✅ Completed successfully for Product #{product.id}."
          
        rescue ::Google::Apis::ClientError => e

          msg = e.message.downcase
          if msg.include?('quota') || msg.include?('limit')
             raise e 
          else
             Rails.logger.error "GOOGLE SYNC JOB: ❌ API Client Error for Product #{product.id}: #{e.message}"
          end
          
        rescue => e
          Rails.logger.error "GOOGLE SYNC JOB: ❌ Generic Failed for Product #{product.id}. Error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end
  end
end
