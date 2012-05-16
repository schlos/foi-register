# Be sure to restart your server when you modify this file.

FoiRegister::Application.config.session_store :cookie_store, :key => '_foi-register_session', :secret => FoiRegister::Application.config.secret_token

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# FoiRegister::Application.config.session_store :active_record_store
