require 'test_helper'

class SessionsControllerTest < ActionController::TestCase

  test "should redirect a user to the new session url when they log out" do
    post :logout
    assert_redirected_to 'http://test.host/admin/sessions/new'
  end

  test "should redirect a user to the admin requests url when they update their password" do
    session[:staff_member_id] = staff_members(:phil).id
    post :update_password, :password => "password", :password_confirmation => "password"
    assert_redirected_to 'http://test.host/admin/requests'
  end

  test "should redirect users to new session url if they try to change their passsword when not logged in" do
    get :change_password
    assert_redirected_to 'http://test.host/admin/sessions/new'

    post :update_password, :password => "1", :password_confirmation => "1"
    assert_redirected_to 'http://test.host/admin/sessions/new'
  end
end
