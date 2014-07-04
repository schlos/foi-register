require 'test_helper'

class ResponseMailerTest < ActionMailer::TestCase

  tests ResponseMailer

  test 'notification for closed request' do
    response = responses(:response_1)
    response.request.state = 'disclosed'
    email = ResponseMailer.email_response(response).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match 'Has this request has been handled satisfactorily?', email.html_part.body.to_s
    assert_match 'Has this request has been handled satisfactorily?', email.text_part.body.to_s
  end

  test "notification for open request" do
    response = responses(:response_1)
    response.request.state = 'assessing'
    email = ResponseMailer.email_response(response).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_no_match /Has this request has been handled satisfactorily\?/, email.html_part.body.to_s
    assert_no_match /Has this request has been handled satisfactorily\?/, email.text_part.body.to_s
  end

end
