# == Schema Information
#
# Table name: responses
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  private_part :text             not null
#  public_part  :text             not null
#  request_id   :integer          not null
#

require 'test_helper'

class ResponseTest < ActiveSupport::TestCase
  test 'should not attempt to send email to requestor with a nil email address' do
    requestor = Requestor.new(:name => 'A test name', :email => nil)
    request = Request.new(:remote_email => nil,
                          :requestor => requestor)
    response = Response.new(:public_part => "text goes here",
                            :request => request)


    ResponseMailer.expects(:email_response).times(0)
    response.send_by_email
  end

  test 'should not attempt to send email to requestor with a blank email address' do
    requestor = Requestor.new(:name => 'A test name', :email => "")
    request = Request.new(:remote_email => nil,
                          :requestor => requestor)
    response = Response.new(:public_part => "text goes here",
                            :request => request)

    ResponseMailer.expects(:email_response).times(0)
    response.send_by_email
  end

  test 'when the request has been imported from alaveteli can_show_private_part? should always return false' do
    requestor = Requestor.new(:name => 'A test name', :email => "me@here.com")
    request = Request.new(:remote_email => nil,
                          :requestor => requestor, :remote_id => nil)
    response = Response.new(:private_part => "text", :request => request)
    assert_equal false, response.can_show_private_part?
  end

  test 'when the request has been imported from alaveteli can_ask_for_feedback? should always return false' do
    requestor = Requestor.new(:name => 'A test name', :email => "me@here.com")
    request = Request.new(:remote_email => nil,
                          :requestor => requestor, :remote_id => nil)
    response = Response.new(:request => request)
    assert_equal false, response.can_ask_for_feedback?
  end

  test 'should return false when calling can_show_private_part? if the private_part is blank' do
    requestor = Requestor.new(:name => 'A test name', :email => "me@here.com")
    request = Request.new(:remote_email => nil,
                          :requestor => requestor, :remote_id => 42)
    response = Response.new(:request => request)
    assert_equal false, response.can_show_private_part?
  end

  test 'should return false when calling can_show_private_part? if the requestor email is blank' do
    requestor = Requestor.new(:name => 'A test name', :email => "")
    request = Request.new(:remote_email => "me@here.com",
                          :requestor => requestor, :remote_id => 42)
    response = Response.new(:request => request, :private_part => "hi")
    assert_equal false, response.can_show_private_part?
  end

  test 'should return true when calling can_show_private_part? if the requestor email and private part are set' do
    requestor = Requestor.new(:name => 'A test name', :email => "me@here.com")
    request = Request.new(:remote_email => "",
                          :requestor => requestor, :remote_id => 42)
    response = Response.new(:request => request, :private_part => "hi")
    assert_equal true, response.can_show_private_part?
  end

  test 'should return true when calling can_ask_for_feedback? if the requestor email is not blank' do
    requestor = Requestor.new(:name => 'A test name', :email => "me@here.com")
    request = Request.new(:remote_email => "",
                          :requestor => requestor, :remote_id => 42)
    response = Response.new(:request => request)
    assert_equal true, response.can_ask_for_feedback?
  end

  test 'should return false when calling can_ask_for_feedback? if the requestor email is blank' do
    requestor = Requestor.new(:name => 'A test name', :email => "")
    request = Request.new(:remote_email => "",
                          :requestor => requestor, :remote_id => 42)
    response = Response.new(:request => request)
    assert_equal false, response.can_ask_for_feedback?
  end
end
