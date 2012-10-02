require 'test_helper'
require 'open-uri'
require 'uri'

class RequestsControllerTest < ActionController::TestCase
  setup do
    session[:staff_member_id] = staff_members(:phil).id
    @request_all_your_info = requests(:all_your_info)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create request" do
    request_attributes = @request_all_your_info.attributes
    request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
    assert_difference('Request.count') do
      post :create, :request => request_attributes
    end

    assert_redirected_to requests_path
  end

  def with_alaveteli
    config = MySociety::Config.load_default()
    host = config['TEST_ALAVETELI_API_HOST']
    if host.nil?
      $stderr.puts "WARNING: skipping Alaveteli integration test.  Set `TEST_ALAVETELI_API_HOST` in config/test.yml to run this test."
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
  
  test "should publish a request to Alaveteli endpoint" do
    with_alaveteli do |host|
      request_attributes = @request_all_your_info.attributes
      title = "request_#{Time.now.to_i}"
      request_attributes["title"] = title
      request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
      assert_difference('Request.count') do
        post :create, :request => request_attributes
      end
      begin
        url = "#{host}/request/#{title}"
        result = open(url).read
      rescue OpenURI::HTTPError => e
        flunk("Failed to fetch #{url}: #{e}")
      end
      assert result =~ /#{title}/, "#{result} did not contain #{title}"
      assert result =~ /#{@request_all_your_info.body}/, "#{result} did not contain #{@request_all_your_info.body}"
      assert_redirected_to requests_path
    end
  end
  
  test "should publish requestor name to Alaveteli if visible" do
    assert @request_all_your_info.is_requestor_name_visible?
    
    with_alaveteli do |host|
      request_attributes = @request_all_your_info.attributes
      title = "request_#{Time.now.to_i}_PIV"
      request_attributes["title"] = title
      request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
      post :create, :request => request_attributes
      begin
        url = "#{host}/request/#{title.downcase}"
        result = open(url).read
      rescue OpenURI::HTTPError => e
        flunk("Failed to fetch #{url}: #{e}")
      end
      
      requestor_name = @request_all_your_info.requestor_name
      assert result =~ /#{requestor_name}/, "#{result} did not contain #{requestor_name}"
    end
  end
  
  test "should not publish requestor name to Alaveteli if not visible" do
    assert !requests(:badgers).is_requestor_name_visible?
    
    with_alaveteli do |host|
      request_attributes = requests(:badgers).attributes
      title = "request_#{Time.now.to_i}_NPINV"
      request_attributes["title"] = title
      request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
      post :create, :request => request_attributes
      begin
        url = "#{host}/request/#{title.downcase}"
        result = open(url).read
      rescue OpenURI::HTTPError => e
        flunk("Failed to fetch #{url}: #{e}")
      end
      
      requestor_name = requests(:badgers).requestor_name
      assert result !~ /#{requestor_name}/, "#{result} contained requestor name '#{requestor_name}'"
    end
  end
  
  test "should send acknowledgement of request" do
    ActionMailer::Base.deliveries = []
    request_attributes = @request_all_your_info.attributes
    request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
    post :create, :request => request_attributes
    assert_redirected_to requests_path
    
    found_ack = false
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == "Your request for information has been received"
        found_ack = true
        assert_equal delivery.to, [@request_all_your_info.requestor.email]
      end
    end
    assert found_ack
  end

  test "should send notification of receipt of request" do
    ActionMailer::Base.deliveries = []
    request_attributes = @request_all_your_info.attributes
    request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
    post :create, :request => request_attributes
    assert_redirected_to requests_path
    
    found_notification = false
    expected_subject = MySociety::Config.get('NOTIFICATION_SUBJECT')
    expected_recipient = MySociety::Config.get('NOTIFICATIONS_TO')
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == expected_subject
        found_notification = true
        assert_equal delivery.to, [expected_recipient]
      end
    end
    assert found_notification
  end

  test "should show request" do
    get :show, :id => @request_all_your_info.id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @request_all_your_info
    assert_response :success
  end

  test "should update request" do
    put :update, :id => @request_all_your_info, :request => @request_all_your_info.attributes
    assert_redirected_to request_path(assigns(:request))
  end

  test "should destroy request" do
    assert_difference('Request.count', -1) do
      delete :destroy, :id => @request_all_your_info
    end

    assert_redirected_to requests_path(:is_admin => "admin")
  end
  
  test "should require a reason when unpublishing" do
    params = requests(:badgers).attributes
    params["is_published"] = false

    assert_raise(RuntimeError, "No reason_for_unpublishing given") do
      put :update, :id => requests(:badgers), :request => params
    end
  end
  
  test "should not require a reason when not unpublishing" do
    params = requests(:badgers).attributes
    params["is_published"] = true

    put :update, :id => requests(:badgers), :request => params
  end
  
  test "should send a notification when unpublishing" do
    params = requests(:badgers).attributes
    params["is_published"] = false

    ActionMailer::Base.deliveries = []
    put :update, :id => requests(:badgers), :request => params, :reason_for_unpublishing => "Libellous"
    
    found_notification = false
    expected_subject = MySociety::Config.get("ALAVETELI_TAKEDOWN_SUBJECT")
    expected_recipient = MySociety::Config.get("ALAVETELI_ADMIN_EMAIL")
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == expected_subject
        found_notification = true
        assert_equal delivery.to, [expected_recipient]
        assert_match delivery.body, /Libellous/
      end
    end
    assert found_notification
  end
  
  test "should have an Atom feed of all requests" do
    get :feed, :is_admin => "admin", :format => "atom", :k => MySociety::Config.get("FEED_AUTH_TOKEN")
    assert_response :success
    assert_equal "application/atom+xml; charset=utf-8", @response.headers['Content-Type']
  end

  test "should authenticate the Atom feed" do
    get :feed, :is_admin => "admin", :format => "atom", :k => "this_is_not_the_correct_key"
    assert_response :forbidden
  end
end
