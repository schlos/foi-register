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
    with_alaveteli do |host|
      token = "QSKmM5lqaXyoZsLdQ2zyKQ=="
      conf = confirmation_links(:valid)
      request = requests(:settled)
      conf.stubs(:request).returns(request)
      ConfirmationLink.expects(:find_by_token).with(token).returns(conf)

      # first we need to create a new request, so we have a remote_id to respond to...
      request.send_to_alaveteli

      # trigger the API call
      post :set_response, :token => token, :state => "not_disclosed"
      assert_response :success

      # check that it worked locally
      assert conf.expired
      assert_equal "not_disclosed", request.requestor_state

      # and for alaveteli
      result = JSON.parse(open("#{host}/request/#{request.remote_id}.json").read)
      assert_equal "rejected", result["described_state"]
      assert_equal "Refused.", result["display_status"]
    end
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