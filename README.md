# Spree Google Shopping (Merchant Center)<br>

![logo_light_mc2](https://github.com/user-attachments/assets/8eecad8c-107d-46a5-8e62-4e061286f251)

<br>
A production-grade Spree Commerce extension that integrates directly with Google Merchant Center. Automatically sync products, variants, inventory, and pricing in real-time using the Content API v2.1

<br>
Includes a full Admin Dashboard for tracking approval status, fixing data quality issues, and managing OAuth connections securely.

<br>

## 🚀 Key Features
1. Real-Time Sync: Products are pushed to Google immediately upon update/create via background jobs.<br>
2. OAuth 2.0 Integration: Secure, token-based authentication (No static JSON key files required).<br>
3. Admin Dashboard: Live visualization of Approved, Pending, and Disapproved products.<br>
4. Data Quality Issues: View specific error messages from Google (e.g., "Missing GTIN", "Image too small") directly in Spree.<br>
5. Granular Control:<br>
  • Set Global Defaults (Target Country, Currency, Shipping Rules).<br>
  • Override attributes per Product (Brand, MPN, GTIN, Gender, Age Group).
6. Drill-Down Taxonomy: Built-in selector for Google's official Product Taxonomy (6,000+ categories).
7. Secure: Uses Rails 7 Active Record Encryption to store OAuth tokens safely.

<br>

## 📦 Installation
1. Add this line to your application's Gemfile:
```ruby
gem 'spree_google_products', '~> 1.0'
```

2. Install the gem:
```ruby
bundle install
```

3. Run the Installer:
This command will copy migrations, generate encryption keys, and seed the Google Taxonomy database.
```bash
bundle exec rails g spree_google_products:install
```

Follow the on-screen prompts to run migrations and seed data.

<br>

## ⚙️ Configuration
### Google Cloud Console Setup<br>
Before using the extension, you must create credentials in Google Cloud.<br>
1. Go to [Google Cloud Console.](https://console.cloud.google.com/)<br>
2. Create a new project (or select existing).<br>
3. Enable API: Go to "APIs & Services" > "Library" -> Search for "Content API for Shopping" -> Enable it.<br>
4. Create Credentials:<br>

   • Go to "APIs & Services" > "Credentials".<br>

   • Click Create Credentials -> OAuth Client ID.<br>

   • Application Type: Web Application.<br>

   • Authorized Redirect URI: https://your-store.com/admin/google_merchant_settings/callback<br>
(Note: Use http://localhost:3000/... for local development).<br>
5. Copy the Client ID and Client Secret.<br>
<br>
<img width="900" height="auto" alt="Screenshot 2026-01-11 at 11 58 54 PM" src="https://github.com/user-attachments/assets/bff8a7cc-050d-4fa1-9bfe-190719ae984a" />
<br>

### Environment Variables<br>
The installer automatically adds these to your .env file. Fill in your Google credentials:<br>

```bash
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

<br>

### Connect in Spree Admin
1. Login to your Spree Admin Panel.
2. Navigate to Google Shopping > Settings (Sidebar).
3. Click Connect Account and log in with the Google Account that manages your Merchant Center.
4. Once connected, enter your Merchant Center ID and Target Country/Currency.
5. Click Save Settings.
<br>
<img width="900" height="auto" alt="Screenshot 2026-01-11 at 11 59 17 PM" src="https://github.com/user-attachments/assets/fea6f8c2-dd1e-443c-8906-dd61869b8226" />
<br>

## 🛠️ Usage

### Dashboard
Visit Google Shopping > Dashboard to see a live overview of your product feed health.
• Approved: Live on Google Shopping.

• Limited: Live but restricted (e.g., adult content, partial regions).

• Disapproved: Critical issues preventing display.

• Sync Now: Force a full catalog sync manually.

<img width="900" height="auto" alt="Screenshot 2026-01-12 at 12 43 34 AM" src="https://github.com/user-attachments/assets/b53174b2-37ee-42ea-9526-00630b46c60e" />

<br>


### Managing Products
You can manage Google-specific attributes in the Product Edit tab under "Google Shopping Attributes".
• GTIN / MPN: Crucial for approval. If your products have barcodes, enter them here.

• Google Category: Use the drill-down selector to pick the exact Google Taxonomy ID.

• Demographics: Set Gender, Age Group, and Condition (New/Used).

<br>
<img width="900" height="auto" alt="Screenshot 2026-01-12 at 12 51 02 AM" src="https://github.com/user-attachments/assets/37c064cf-d794-42bb-90eb-3ade6ec2bbab" />
<img width="900" height="auto" alt="Screenshot 2026-01-12 at 12 32 11 AM" src="https://github.com/user-attachments/assets/aee1955d-481f-47d3-a15f-c7a4670f9e78" />
<img width="871" height="456" alt="Screenshot 2026-01-12 at 12 39 32 AM" src="https://github.com/user-attachments/assets/2a509733-2151-48c0-8b63-2d3db654b797" />

<br>

### Background Jobs
This extension uses ActiveJob. Ensure you have a queue adapter configured (Sidekiq, Solid Queue, or Delayed Job) for production.<br>
• Spree::GoogleShopping::SyncProductJob: Syncs individual product updates.<br>
• Spree::GoogleShopping::SyncAllJob: Bulk syncs entire catalog.<br>
• Spree::GoogleShopping::FetchStatusJob: Pulls approval status from Google.<br>

<br>

## 🔒 Security & Encryption
This plugin strictly adheres to security best practices. OAuth Refresh Tokens are encrypted at rest in the database using Rails Active Record Encryption.<br>

The installer generates these keys in your .env file automatically:

ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY<br>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY<br>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT<br>

<br>

### ⚠️ IMPORTANT: Keep these keys safe. If you lose them, you will need to disconnect and reconnect your Google Account.

<br>

## 🗑️ Uninstallation
To cleanly remove the extension, drop tables, and cleanup migrations, run:

```bash
bundle exec rails g spree_google_products:uninstall
```

This command will ask for confirmation before dropping the Google-related tables.

<br>

## 🗺️ Roadmap
• [x] Google Merchant Center (Content API) Sync<br>
• [x] Product Approval Status Dashboard<br>
• [x] Issue Reporting<br>
• [ ] Google Ads Integration: Create Performance Max campaigns directly from Spree.<br>
• [ ] Conversion Tracking: Auto-inject Google Ads conversion pixels.<br>
• [ ] Free Listings: specialized support for "Free Listings" enhanced attributes.<br>

<br>

## ❓ FAQ
Q: I get "Missing Active Record encryption credential" error.
A: Restart your server. The encryption keys are loaded from .env on boot. If using a custom deployment, ensure the ACTIVE_RECORD_ENCRYPTION_* variables are set in your environment.

Q: Why are my products still "Pending" after syncing?
A: Google takes 3-5 business days to review new products. Check the Dashboard for real-time status updates.

Q: Can I sync to multiple countries?
A: Currently, the extension supports one primary Target Country per store. Multi-country feeds via the "Shipping" attribute are planned for v2.0.

<br>

### License
Copyright (c) 2026. Released under the BSD-3-Clause [License](https://github.com/umeshravani/spree_google_products/blob/main/LICENSE.md).
