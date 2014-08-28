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
end
