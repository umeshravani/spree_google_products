module Spree
  module Admin
    module GoogleShopping
      class DashboardController < Spree::Admin::BaseController
        helper Spree::Admin::BaseHelper
        
        before_action :check_connection, only: [:index]

        def index
          @store = Spree::Store.default
          @credential = @store.google_credential

          @stats = { approved: 0, limited: 0, pending: 0, disapproved: 0 }
          @last_sync = nil

          if @credential&.active? && @credential.merchant_center_id.present?
            begin
              service = Spree::GoogleShopping::StatusService.new(@credential)
              fetched_stats = service.fetch_counts
              
              if fetched_stats[:error]
                flash.now[:error] = "Could not fetch live stats from Google. Data may be delayed."
              else
                @stats = fetched_stats
              end
              
              @last_sync = @credential.last_sync_at

            rescue Spree::GoogleTokenService::TokenError, Signet::AuthorizationError, Google::Auth::AuthorizationError => e
              
              Rails.logger.error "GOOGLE DASHBOARD: Token expired or revoked. Resetting credential. Error: #{e.message}"
              
              @credential.update_columns(access_token: nil, expires_at: nil)
              
              flash[:error] = "Your Google connection has expired. Please sign in again."
              redirect_to edit_admin_google_merchant_settings_path
            end
          end
        end

        def sync
          @store = Spree::Store.default
          
          if @store.google_credential&.merchant_center_id.blank?
             flash[:error] = "Please enter your Google Merchant Center ID in Settings before syncing."
             redirect_to edit_admin_google_merchant_settings_path
             return
          end

          product_count = 0
          Spree::Product.active.find_each do |product|
            Spree::GoogleShopping::SyncProductJob.perform_later(product.id)
            product_count += 1
          end
          
          if product_count == 0
            flash[:warning] = "No active products found to sync."
          else
            Rails.cache.delete("google_shopping_stats_#{@store.google_credential.merchant_center_id}")
            flash[:success] = "Sync started for #{product_count} products! Statuses will update shortly."
          end

          redirect_to admin_google_shopping_dashboard_path
        end

        private

        def check_connection
          credential = Spree::Store.default.google_credential
          
          unless credential&.active?
            flash[:warning] = "Please connect your Google Merchant Center account to access the dashboard."
            redirect_to edit_admin_google_merchant_settings_path
          end
        end
      end
    end
  end
end
