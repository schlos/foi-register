require 'test_helper'
require 'open-uri'
require 'uri'

class RequestorConfirmationControllerTest < ActionController::TestCase
  test "should show confirmation form if token is valid" do
    token = "QSKmM5lqaXyoZsLdQ2zyKQ=="
    conf = confirmation_links(:valid)
    conf.stubs(:request).returns(requests(:settled))
    ConfirmationLink.expects(:find_by_token).with(token).returns(conf)
    get :show, :token => token
    assert_response :success
  end

  test "should update the response" do
    token = "QSKmM5lqaXyoZsLdQ2zyKQ=="
    conf = confirmation_links(:valid)
    request = requests(:settled)
    conf.stubs(:request).returns(request)
    ConfirmationLink.expects(:find_by_token).with(token).returns(conf)

    post :set_response, :token => token, :state => "not disclosed"
    assert_response :success

    assert conf.expired
    assert_equal "not disclosed", request.requestor_state
  end

  test "should redirect to index if the request is not found" do
    token = "QSKmM5lqaXyoZsLdQ2zyKQ=="
    conf = confirmation_links(:valid)
    ConfirmationLink.expects(:find_by_token).with(token).returns(conf)
    get :show, :token => token
    assert_redirected_to :root
  end

  test "should redirect to index if token is invalid" do
    token = "1p-QTkAiUUhFBHWvcYwSiQ=="
    conf = confirmation_links(:expired)
    ConfirmationLink.expects(:find_by_token).with(token).returns(conf)
    get :show, :token => token
    assert_redirected_to :root
  end
end