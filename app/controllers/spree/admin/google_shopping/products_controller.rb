require 'kaminari'

module Spree
  module Admin
    module GoogleShopping
      class ProductsController < Spree::Admin::ResourceController

        def index
          @per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 25

          @search = collection.ransack(params[:q])
          
          @collection = @search.result(distinct: true)
                               .includes(master: [:images, :default_price])
                               .page(params[:page])
                               .per(@per_page)
        end

        def collection
          return @collection if @collection.present?
          
          @collection = Spree::Product.accessible_by(current_ability, :read)
                                      .includes(:google_product_attribute)
        end

        def edit
          @product = Spree::Product.friendly.find(params[:id])
          @product.build_google_product_attribute unless @product.google_product_attribute
        end

        def update
          @product = Spree::Product.friendly.find(params[:id])
          
          if @product.update(product_params)
            Spree::GoogleShopping::SyncProductJob.perform_later(@product.id)
            
            flash[:success] = "Product updated. Syncing to Google Merchant Center..."
            redirect_to admin_google_shopping_products_path
          else
            flash[:error] = "Could not update product."
            render :edit
          end
        end

        def issues
          @product = Spree::Product.friendly.find(params[:id])
          @variant = Spree::Variant.find_by(id: params[:variant_id])
          
          if @variant
            @google_attr = Spree::GoogleVariantAttribute.find_by(variant_id: @variant.id)
            @issues = @google_attr&.google_issues || []
          else
            flash[:error] = "Variant not found."
            redirect_to admin_google_shopping_products_path
          end
        end

        def sync
          @product = Spree::Product.friendly.find(params[:id])
          
          if @product
            Spree::GoogleShopping::SyncProductJob.perform_later(@product.id)
            flash[:success] = "Sync queued for '#{@product.name}'."
          else
            flash[:error] = "Product not found."
          end
          
          redirect_back(fallback_location: admin_google_shopping_products_path)
        end

        def sync_all
           Spree::GoogleShopping::SyncAllJob.perform_later
           flash[:success] = "Sync All background job started!"
           redirect_back(fallback_location: admin_google_shopping_products_path)
        end

        private

        def model_class
          Spree::Product
        end

        def product_params
          params.require(:product).permit(
            google_product_attribute_attributes: [
              :id, 
              :brand, 
              :product_type,
              :google_product_category, 
              :gender, 
              :age_group, 
              :condition, 
              :gtin, 
              :mpn,
              :sale_start_at,
              :sale_end_at,
              :min_handling_time,
              :max_handling_time
            ]
          )
        end
      end
    end
  end
end
