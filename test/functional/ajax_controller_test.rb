require 'test_helper'

class AjaxControllerTest < ActionController::TestCase
  test "should not get requestors unless authenticated" do
    get :requestors
    assert_response :redirect
  end

  test "should get requestors when authenticated" do
    session[:staff_member_id] = staff_members(:phil).id
    get :requestors
    assert_response :success
  end

end
