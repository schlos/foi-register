# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
FoiRegister::Application.initialize!

# Load the configuration file
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))
load "config.rb"
if ENV["RAILS_ENV"] == "test" 
    MySociety::Config.set_file(File.join(Rails.root, 'config', 'test'), true)
else
    MySociety::Config.set_file(File.join(Rails.root, 'config', 'general'), true)
end
