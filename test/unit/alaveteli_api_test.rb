# Test the AlaveteliApi class

require 'test_helper'

class AlaveteliAPITestCase < ActiveSupport::TestCase

  test "pull_from_alaveteli? should return true" do
    assert_equal AlaveteliApi.pull_from_alaveteli?, true
  end

  test "test_alaveteli_secure should return false" do
    assert_equal AlaveteliApi.alaveteli_secure?, false
  end

  test "fetch_feed should call the right api url" do
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => '[]')
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should send last_event_id to alaveteli" do
    AlaveteliFeed.expects(:last_event_id).returns(1000)
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1000"
    stub_request(:get, expected_feed_url).to_return(:body => '[]')
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should skip existing requests" do
    created_in_app = requests(:created_in_app)
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 1,
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => created_in_app.remote_id,
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => nil
      }
    ])
    # We shouldn't create any new records
    Request.stubs(:new).never
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should raise an error on empty user_urls" do
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 1,
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => 1000000, # High enough not to be in our test DB
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => nil,
        :user_url => nil
      }
    ])
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    assert_raises AlaveteliApi::AlaveteliApiError do
      AlaveteliApi.fetch_feed
    end
  end

  test "fetch_feed should find existing requestors" do
    external_user = requestors(:external_user)
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 1,
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => 1000000, # High enough not to be in our test DB
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => external_user.name,
        :user_url => external_user.external_url
      }
    ])
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    Requestor.expects(:new).never
    mock_request = mock()
    mock_request.expects(:save!)
    Request.expects(:new).returns(mock_request)
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should create new requestors" do
    new_user_url = 'http://www.whatdotheyknow.com/users/new_test_user'
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 1,
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => 1000000, # High enough not to be in our test DB
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => 'New Test User',
        :user_url => new_user_url
      }
    ])
    mock_requestor = mock()
    mock_requestor.expects(:save!)
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    Requestor.expects(:find_by_external_url_scheme_insensitive).with(new_user_url).returns(nil)
    Requestor.expects(:new).with(
        :name => 'New Test User',
        :external_url => new_user_url
      ).returns(mock_requestor)
    mock_request = mock()
    mock_request.expects(:save!)
    Request.expects(:new).returns(mock_request)
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should create new requests" do
    external_user = requestors(:external_user)
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 1,
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => 1000000, # High enough not to be in our test DB
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => external_user.name,
        :user_url => external_user.external_url
      }
    ])
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    mock_request = mock()
    mock_request.expects(:save!)
    Request.expects(:new).with(
        :medium => "alaveteli",
        :state => "new",
        :remote_url => "https://www.whatdotheyknow.com/request/test",
        :remote_email => "request-1-a@whatdotheyknow.com",
        :requestor => external_user,
        :title => "test",
        :body => "Test",
        :date_received => Time.iso8601("2015-03-11T10:10:00+00:00"),
        :due_date => Time.iso8601("2015-03-11T10:10:00+00:00") + 28.days
      ).returns(mock_request)
    AlaveteliApi.fetch_feed
  end

  test "fetch_feed should update last_event_id" do
    external_user = requestors(:external_user)
    feed_response = ActiveSupport::JSON.encode([
      {
        :body => "Test",
        :created_at => "2015-03-11T10:10:00+00:00",
        :event_id => 2, # Default is 1
        :event_type => "sent",
        :request_email => "request-1-a@whatdotheyknow.com",
        :request_id => 1000000, # High enough not to be in our test DB
        :request_url => "https://www.whatdotheyknow.com/request/test",
        :title => "test",
        :user_name => external_user.name,
        :user_url => external_user.external_url
      }
    ])
    expected_feed_url = "#{MySociety::Config.get('ALAVETELI_FEED_URL')}?k=#{MySociety::Config.get('ALAVETELI_API_KEY')}&since_event_id=1"
    stub_request(:get, expected_feed_url).to_return(:body => feed_response)
    AlaveteliApi.fetch_feed
    assert_equal 2, AlaveteliFeed.last_event_id
  end
end
