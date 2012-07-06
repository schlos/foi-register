require 'test_helper'

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
