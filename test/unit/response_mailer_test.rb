require 'test_helper'

class ResponseMailerTest < ActionMailer::TestCase

  tests ResponseMailer

  test 'notification for closed request' do
    response = responses(:response_1)
    response.request.state = 'disclosed'
    response.stubs(:can_ask_for_feedback?).returns(true)
    email = ResponseMailer.email_response(response).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match 'Our response is as follows:', email.html_part.body.to_s
    assert_match 'Our response is as follows:', email.text_part.body.to_s
  end

  test 'notification for open request' do
    response = responses(:response_1)
    response.request.state = 'assessing'
    email = ResponseMailer.email_response(response).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match 'This is an update', email.html_part.body.to_s
    assert_no_match /Our response is as follows:\?/, email.html_part.body.to_s
    assert_no_match /Our response is as follows:\?/, email.text_part.body.to_s
  end

end
