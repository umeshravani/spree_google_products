# spree_google_products.gemspec
require_relative 'lib/spree_google_products/version'

Gem::Specification.new do |spec|
  spec.name    = 'spree_google_products'
  spec.version = SpreeGoogleProducts::VERSION
  spec.authors = ['Umesh Ravani']
  spec.email   = ['umeshravani98@gmail.com']
  spec.summary = 'Production grade Google Merchant & Ads integration for Spree'
  spec.license = 'BSD-3-Clause'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'spree_core', '>= 4.3.0'
  spec.add_dependency 'spree_backend'
  
  # For Google Ads & Performance Max
  spec.add_dependency 'google-ads-googleads', '~> 24.0'
  
  # For the OAuth handshake
  spec.add_dependency 'omniauth-google-oauth2', '~> 1.0'
  spec.add_dependency 'googleauth', '~> 1.0'
  spec.add_dependency 'dotenv-rails', '>= 2.7'
  spec.add_dependency 'google-apis-content_v2_1'
end
