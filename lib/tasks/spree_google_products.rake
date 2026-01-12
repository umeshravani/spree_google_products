namespace :spree_google_shopping do
  desc "Download and import official Google Taxonomy"
  task seed_taxons: :environment do
    require 'open-uri'

    url = "https://www.google.com/basepages/producttype/taxonomy-with-ids.en-US.txt"
    puts "⬇️  Downloading Google Taxonomy from: #{url}..."

    ActiveRecord::Base.transaction do
      Spree::GoogleTaxon.delete_all
      
      count = 0
      data = []
      
      URI.open(url) do |file|
        file.each_line do |line|
          next if line.start_with?('#') || line.strip.empty?
          
          parts = line.strip.split(' - ', 2)
          
          if parts.length == 2
            data << { 
              google_id: parts[0], 
              name: parts[1]
            }
            count += 1
          end

          if data.size >= 1000
            Spree::GoogleTaxon.insert_all(data)
            print "."
            data = []
          end
        end
      end
      
      Spree::GoogleTaxon.insert_all(data) if data.any?
      puts "\n✅ Successfully seeded #{count} Google Taxons!"
    end
  end

  desc "Remove all tables and data created by Spree Google Products"
  task cleanup: :environment do
    tables = %w[spree_google_credentials spree_google_product_attributes spree_google_variant_attributes spree_google_taxons]
    
    tables.each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        ActiveRecord::Base.connection.drop_table(table, force: :cascade)
        puts "🔥 Dropped table: #{table}"
      else
        puts "   Table #{table} does not exist, skipping."
      end
    end
    puts "✅ Database cleanup complete."
  end
end
