require 'google/apis/content_v2_1'

module Spree
  module GoogleShopping
    class ContentService
      def initialize(credential)
        @credential = credential
        @service = Google::Apis::ContentV2_1::ShoppingContentService.new
        @service.authorization = Spree::GoogleTokenService.new(@credential).token
      end

      def push_product(product)
        ([product.master] + product.variants).each do |variant|
          price = price_object_for(variant)
          
          if price.nil? || price.amount.blank? || price.amount.zero?
            next
          end

          product_obj = build_product_payload(variant)
          
          begin
            @service.insert_product(@credential.merchant_center_id, product_obj)
            update_status(variant, 'pending', [])
          rescue Google::Apis::ClientError => e
            handle_google_error(variant, e)
          end
        end
      end

      def fetch_product_status(variant)
        return unless variant.sku.present?
        
        g_id = "online:en:#{@credential.target_country}:#{variant.sku}"
        
        begin
          product_status = @service.get_productstatus(@credential.merchant_center_id, g_id)
          
          shopping_status = product_status.destination_statuses.find { |s| s.destination == "Shopping" }
          
          final_status = case shopping_status&.status
                         when 'approved' then 'active'
                         when 'disapproved' then 'disapproved'
                         when 'pending' then 'pending'
                         else 'pending'
                         end
          
          issues = product_status.item_level_issues.map do |issue|
            { "description" => issue.description, "detail" => issue.detail, "code" => issue.code }
          end
          
          update_status(variant, final_status, issues)
          Rails.logger.info "GOOGLE STATUS FETCH: #{variant.sku} is now '#{final_status}'"
          
        rescue Google::Apis::ClientError => e
          if e.status_code == 404
            update_status(variant, 'not_found_on_google', [])
          else
            Rails.logger.error "GOOGLE STATUS ERROR: #{e.message}"
          end
        end
      end

      private

      def price_object_for(variant)
        variant.price_in(@credential.target_currency)
      end

      def build_product_payload(variant)
        product = variant.product
        g_prod_attr = product.google_product_attribute 
        g_var_attr = variant.google_variant_attribute 
        
        brand = g_prod_attr&.brand.presence || product.property('brand') || 'Generic'
        
        raw_product_type = g_prod_attr&.product_type.presence || @credential.default_product_type
        product_types_list = raw_product_type.present? ? [raw_product_type] : []

        google_category_id = g_prod_attr&.google_product_category.presence || @credential.default_google_product_category

        raw_gtin = g_var_attr&.gtin.presence || g_prod_attr&.gtin.presence
        gtin = (raw_gtin && raw_gtin.to_s.length >= 8) ? raw_gtin.to_s : nil
        
        mpn = g_var_attr&.mpn.presence || g_prod_attr&.mpn.presence || variant.sku

        gender = g_prod_attr&.gender.presence 
        age_group = g_prod_attr&.age_group.presence
        condition = g_prod_attr&.condition.presence || 'new'

        price_obj = price_object_for(variant)
        current_price = price_obj.amount
        original_price = price_obj.compare_at_amount
        
        google_price = nil
        google_sale_price = nil
        sale_date_range = nil

        if original_price.present? && original_price > current_price
          google_price = { value: original_price.to_s, currency: @credential.target_currency }
          google_sale_price = { value: current_price.to_s, currency: @credential.target_currency }
          
          start_date = g_prod_attr&.sale_start_at
          end_date = g_prod_attr&.sale_end_at

          if start_date.present? && end_date.present?
            start_iso = start_date.beginning_of_day.iso8601
            end_iso = end_date.end_of_day.iso8601
            sale_date_range = "#{start_iso}/#{end_iso}"
          end
        else
          google_price = { value: current_price.to_s, currency: @credential.target_currency }
          google_sale_price = nil
        end
        
        product_input_weight = nil
        if variant.weight.present? && variant.weight > 0
          product_input_weight = Google::Apis::ContentV2_1::ProductShippingWeight.new(
            value: variant.weight.to_f,
            unit: 'kg'
          )
        end

        product_input_length = nil
        product_input_width = nil
        product_input_height = nil

        if variant.depth.present? && variant.width.present? && variant.height.present?
           product_input_length = Google::Apis::ContentV2_1::ProductShippingDimension.new(value: variant.depth.to_f, unit: 'cm')
           product_input_width = Google::Apis::ContentV2_1::ProductShippingDimension.new(value: variant.width.to_f, unit: 'cm')
           product_input_height = Google::Apis::ContentV2_1::ProductShippingDimension.new(value: variant.height.to_f, unit: 'cm')
        end

        min_days = g_prod_attr&.min_handling_time.presence || @credential.default_min_handling_time
        max_days = g_prod_attr&.max_handling_time.presence || @credential.default_max_handling_time
        
        shipping_array = []
        if min_days.present? && max_days.present?
          shipping_array << Google::Apis::ContentV2_1::ProductShipping.new(
            country: @credential.target_country,
            service: "Standard",
            price: Google::Apis::ContentV2_1::Price.new(value: "0.00", currency: @credential.target_currency),
            min_handling_time: min_days.to_i,
            max_handling_time: max_days.to_i
          )
        end

        final_link = product_url(product)
        final_image_link = image_url(variant)

        Google::Apis::ContentV2_1::Product.new(
          offer_id: variant.sku, 
          title: product.name,
          description: product.description&.truncate(5000) || product.name,
          
          link: final_link,
          image_link: final_image_link,
          
          content_language: 'en',
          target_country: @credential.target_country,
          channel: 'online',
          availability: variant.in_stock? ? 'in stock' : 'out of stock',
          condition: condition,
          price: google_price,
          sale_price: google_sale_price,
          sale_price_effective_date: sale_date_range,
          shipping_weight: product_input_weight,
          shipping_length: product_input_length,
          shipping_width: product_input_width,
          shipping_height: product_input_height,
          shipping: shipping_array.presence,
          brand: brand,
          product_types: product_types_list,
          google_product_category: google_category_id,
          gtin: gtin,
          mpn: mpn,
          identifier_exists: gtin.present?,
          gender: gender,
          age_group: age_group,
          item_group_id: product.id.to_s 
        )
      end

      def product_url(product)
        store_url = Spree::Store.default.url
        clean_host = store_url.sub(/^https?:\/\//, '').chomp('/')
        
        Spree::Core::Engine.routes.url_helpers.product_url(
          product, 
          host: clean_host, 
          protocol: 'https'
        )
      end

      def image_url(variant)
        image = variant.images.first || variant.product.master.images.first
        return "" unless image
        
        store_url = Spree::Store.default.url
        
        clean_host = store_url.sub(/^https?:\/\//, '').chomp('/')

        url = Rails.application.routes.url_helpers.rails_blob_url(
          image.attachment, 
          host: clean_host, 
          protocol: 'https' 
        )
        
        url
      rescue => e
        Rails.logger.error "GOOGLE IMAGE ERROR: #{e.message}"
        "" 
      end

      def update_status(variant, status, issues)
        attr = Spree::GoogleVariantAttribute.find_or_initialize_by(variant_id: variant.id)
        attr.google_status = status
        attr.google_issues = issues
        attr.last_synced_at = Time.current
        attr.save!
      end

      def handle_google_error(variant, error)
        error_json = JSON.parse(error.body) rescue {}
        message = error_json.dig('error', 'message') || error.message
        
        update_status(variant, 'disapproved', [{ "description" => "API Error", "detail" => message }])
        Rails.logger.error "GOOGLE SYNC ERROR (Variant #{variant.id}): #{message}"
      end
    end
  end
end
