require 'test_helper'

class RedirectionControllerTest < ActionController::TestCase
  test "should get front" do
    get :front
    assert_response :redirect
  end

end
