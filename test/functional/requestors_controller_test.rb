require 'test_helper'

class RequestorsControllerTest < ActionController::TestCase
  setup do
    @requestor = requestors(:robin)
    session[:staff_member_id] = staff_members(:phil).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:requestors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create requestor" do
    assert_difference('Requestor.count') do
      post :create, :requestor => @requestor.attributes
    end

    assert_redirected_to requestor_path(assigns(:requestor))
  end

  test "should show requestor" do
    get :show, :id => @requestor
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @requestor
    assert_response :success
  end

  test "should update requestor" do
    put :update, :id => @requestor, :requestor => @requestor.attributes
    assert_redirected_to requestor_path(assigns(:requestor))
  end

  test "should destroy requestor" do
    assert_difference('Requestor.count', -1) do
      delete :destroy, :id => @requestor
    end

    assert_redirected_to requestors_path(:is_admin => "admin")
  end
end
