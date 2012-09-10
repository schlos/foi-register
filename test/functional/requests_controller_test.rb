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

  test "should publish a request to Alaveteli endpoint" do
    config = MySociety::Config.load_default()
    host = config['TEST_ALAVETELI_API_HOST']
    if host.nil?
      $stderr.puts "WARNING: skipping Alaveteli integration test.  Set `TEST_ALAVETELI_API_HOST` in config/test.yml to run this test."
    else
      endpoint = "#{host}/api/v2"
      config['ALAVETELI_API_ENDPOINT'] = endpoint
      config['ALAVETELI_API_KEY'] = '3'
      begin
        request_attributes = @request_all_your_info.attributes
        title = "request_#{Time.now.to_i}"
        request_attributes["title"] = title
        request_attributes[:requestor_attributes] = {:id => request_attributes.delete("requestor_id")}
        assert_difference('Request.count') do
          post :create, :request => request_attributes
        end
        result = open("#{host}/request/#{title}").read
        assert result =~ /#{title}/, "#{result} did not contain #{title}"
        assert result =~ /#{@request_all_your_info.body}/, "#{result} did not contain #{@request_all_your_info.body}"
        assert_redirected_to requests_path
      rescue Errno::ECONNREFUSED => e
        raise "TEST_ALAVETELI_API_HOST set in test.yml but no Alaveteli server running"
      ensure
        config['ALAVETELI_API_ENDPOINT'] = nil
      end
    end
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

    assert_redirected_to requests_path
  end
end
