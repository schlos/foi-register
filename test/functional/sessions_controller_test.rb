require 'test_helper'

class SessionsControllerTest < ActionController::TestCase

  test "should redirect a user to the new session url when they log out" do
    post :logout
    assert_redirected_to 'http://test.host/admin/sessions/new'
  end

end
