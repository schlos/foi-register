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
    assert_match CGI::escapeHTML(MySociety::Config.get("PAGE_TITLE_SUFFIX")), response.body.to_s
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

  test "doesn't send email when request isn't created" do
    assert_difference 'ActionMailer::Base.deliveries.size', 0 do
      post :create, :request => {:requestor_attributes => {}}
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
    params = @request_all_your_info.attributes
    params["due_date"] = params["due_date"].strftime("%d/%m/%Y")

    put :update, :id => @request_all_your_info, :request => params
    assert_redirected_to request_path(assigns(:request), :is_admin => 'admin')
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
    params["due_date"] = params["due_date"].strftime("%d/%m/%Y")

    assert_raise(RuntimeError, "No reason_for_unpublishing given") do
      put :update, :id => requests(:badgers), :request => params
    end
  end

  test "should not require a reason when not unpublishing" do
    params = requests(:badgers).attributes
    params["is_published"] = true
    params["due_date"] = params["due_date"].strftime("%d/%m/%Y")

    put :update, :id => requests(:badgers), :request => params
  end

  test "should send a notification when unpublishing" do
    params = requests(:badgers).attributes
    params["is_published"] = false
    params["due_date"] = params["due_date"].strftime("%d/%m/%Y")

    ActionMailer::Base.deliveries = []
    put :update, :id => requests(:badgers), :request => params, :reason_for_unpublishing => "Libellous"

    found_notification = false
    expected_subject = MySociety::Config.get("ALAVETELI_TAKEDOWN_SUBJECT")
    expected_recipient = MySociety::Config.get("ALAVETELI_ADMIN_EMAIL")
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == expected_subject
        found_notification = true
        assert_equal delivery.to, [expected_recipient]
        assert_match(/Libellous/, delivery.body.to_s)
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

  test 'should limit the items to those created in the last 30 days by default' do
    get :feed, :is_admin => "admin", :format => "atom", :k => MySociety::Config.get("FEED_AUTH_TOKEN")
    assert response.body =~ /All your information/
    assert response.body =~ /Badgers/
    assert response.body !~ /In Olden Days/
  end

  test 'should accept a parameter for the number of days past to show' do
    get :feed, :is_admin => "admin",
               :format => "atom",
               :k => MySociety::Config.get("FEED_AUTH_TOKEN"),
               :days => 60
    assert response.body =~ /All your information/
    assert response.body =~ /Badgers/
    assert response.body =~ /In Olden Days/
  end

  test 'should return an empty feed if there are no requests in the given period' do
    get :feed, :is_admin => "admin",
               :format => "atom",
               :k => MySociety::Config.get("FEED_AUTH_TOKEN"),
               :days => 1
    assert_response :success
  end

  test 'should not find requests by email when searching from the front end interface' do
    build_xapian_index
    get :search, :q => 'seb@mysociety.org'
    assert response.body !~ /Badgers/
  end

  test 'should find requests by email when searching from the admin interface' do
    build_xapian_index
    get :search, :q => 'seb@mysociety.org',
                 :is_admin => 'admin'
    assert response.body =~ /Badgers/
  end

  test 'should find requests by public requestor name when searching from the front end interface' do
    build_xapian_index
    get :search, :q => 'houston'
    assert response.body =~ /All your information/
  end

  test 'should not find requests by non-public requestor name when searching from the front end interface' do
    build_xapian_index
    get :search, :q => 'bacon'
    assert response.body !~ /Badgers/
  end

  test 'should find requests by public requestor name when searching from the admin interface' do
    build_xapian_index
    get :search, :q => 'houston',
                 :is_admin => 'admin'
    assert response.body =~ /All your information/
  end

  test 'should find requests by non-public requestor name when searching from the admin interface' do
    build_xapian_index
    get :search, :q => 'bacon',
                 :is_admin => 'admin'
    assert response.body =~ /Badgers/
  end

  test 'should not find requests by private response text when searching from the front end interface' do
    build_xapian_index
    get :search, :q => 'private part of response'
    assert response.body !~ /All your information/
  end

  test 'should find requests by private response text when searching from the admin interface' do
    build_xapian_index
    get :search, :q => 'private part of response',
                 :is_admin => 'admin'
    assert response.body =~ /All your information/
  end

  test "should not show days overdue for disclosed requests" do
    build_xapian_index
    get :search, :q => "QuestionAnswered",
                 :is_admin => 'admin'
    assert response.body =~ /<span class='badge '> n\/a<\/span>/
  end

  test "should not show days overdue for non_disclosed requests" do
    build_xapian_index
    get :search, :q => "Unanswerable",
                 :is_admin => 'admin'
    assert response.body =~ /<span class='badge '> n\/a<\/span>/
  end

  test "should show days overdue for new requests" do
    build_xapian_index
    get :search, :q => "Overdue",
                 :is_admin => 'admin'
    assert response.body =~ /<span class='badge badge-warning'> -10<\/span>/
  end
end
