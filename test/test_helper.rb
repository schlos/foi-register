ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'action_view/base'
require 'mocha/setup'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Build the xapian index if not already built
  def build_xapian_index()
    models = [Request, Response]
    if ! $existing_db
      ActsAsXapian::WriteableIndex.rebuild_index(models, verbose=false)
      $existing_db = true
    end
  end
end
