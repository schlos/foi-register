# Load the rails application
require File.expand_path('../application', __FILE__)

# Load the configuration file
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))
load "config.rb"
if ENV["RAILS_ENV"] == "test" 
    MySociety::Config.set_file(File.join(Rails.root, 'config', 'test'), true)
else
    MySociety::Config.set_file(File.join(Rails.root, 'config', 'general'), true)
end

asset_host = MySociety::Config::get("ASSET_HOST", "")
if !(asset_host.nil? || asset_host.empty?)
    FoiRegister::Application.configure do
        config.action_controller.asset_host = asset_host
    end
end

# Initialize the rails application
FoiRegister::Application.initialize!
