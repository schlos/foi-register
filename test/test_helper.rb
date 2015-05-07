ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'action_view/base'
require 'mocha/setup'
require 'webmock/test_unit'

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

  # Wrapper for tests that need an Alaveteli connection
  def with_alaveteli
    # Allow real network requests for these, until we have the time to mock
    # out all of the calls to Alaveteli
    WebMock.allow_net_connect!
    config = MySociety::Config.load_default()
    host = config['TEST_ALAVETELI_API_HOST']
    if host.nil?
      $stderr.puts "WARNING: skipping Alaveteli integration test.  Set `TEST_ALAVETELI_API_HOST` to run"
    else
      endpoint = "#{host}/api/v2"
      config['ALAVETELI_API_ENDPOINT'] = endpoint
      config['ALAVETELI_API_KEY'] = '3'

      begin
        yield host
      rescue Errno::ECONNREFUSED => e
        raise "TEST_ALAVETELI_API_HOST set in test.yml but no Alaveteli server running"
      ensure
        config['ALAVETELI_API_ENDPOINT'] = nil
      end
    end
  end
end
