require 'test_helper'
require 'uri'

class ResponsesControllerTest < ActionController::TestCase
  setup do
    @response_1 = responses(:response_1)
    session[:staff_member_id] = staff_members(:phil).id
  end

  test "should get index" do
    get :index, :request_id => requests(:all_your_info).id
    assert_response :success
    assert_not_nil assigns(:responses)
  end

  test "should create response" do
    assert_difference('Response.count') do
      post :create, :response => @response_1.attributes, :request_id => @response_1.request_id
    end

    assert_redirected_to request_response_path(@response_1.request, assigns(:response))
  end

  test "should publish a response to Alaveteli endpoint" do
    config = MySociety::Config.load_default()
    host = config['TEST_ALAVETELI_API_HOST']
    if host.nil?
      $stderr.puts "WARNING: skipping Alaveteli integration test.  Set `TEST_ALAVETELI_API_HOST` to run"
    else
      endpoint = "#{host}/api/v2"
      config['ALAVETELI_API_ENDPOINT'] = endpoint
      config['ALAVETELI_API_KEY'] = '3'

      begin
        # first we need to create a new request, so we have a remote_id to respond to...
        @response_1.request.send_to_alaveteli

        response_attributes = @response_1.attributes
        params = @response_1.attributes
        params['attachments_attributes'] = {}

        @response_1.attachments.each_with_index do |attachment, n|
          params['attachments_attributes'][n] = {'file' => fixture_file_upload("files/#{attachment['file']}", attachment['content_type'])}
        end
        post :create, :response => params, :request_id => @response_1.request.id
        result = open("#{host}/request/#{@response_1.request.remote_id}").read
        assert result =~ /#{@response_1.public_part}/, "#{result} did not contain #{@response_1.public_part}"
        # The following tests have the condition hard coded because
        # the filenames are munged in the Alaveteli display area using
        # code that would otherwise need refactoring
        assert result =~ /attachment%201.txt/
        assert result =~ /attachment%202.pdf/
        assert_redirected_to request_response_path(@response_1.request, assigns(:response))
      rescue Errno::ECONNREFUSED => e
        raise "TEST_ALAVETELI_API_HOST set in test.yml but no Alaveteli server running"
      ensure
        config['ALAVETELI_API_ENDPOINT'] = nil
      end
    end
  end




  test "should show response" do
    get :show, :request_id => @response_1.request.id, :id => @response_1
    assert_response :success
  end

  test "should get edit" do
    get :edit, :request_id => @response_1.request.id, :id => @response_1
    assert_response :success
  end

  test "should update response" do
    put :update, :request_id => @response_1.request.id, :id => @response_1, :response => @response_1.attributes
    assert_redirected_to request_path(assigns(:response).request)
  end

  test "should destroy response" do
    assert_difference('Response.count', -1) do
      delete :destroy, :request_id => @response_1.request.id, :id => @response_1
    end

    assert_redirected_to request_responses_path(@response_1.request)
  end
end
