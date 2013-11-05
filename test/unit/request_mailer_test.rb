require 'test_helper'

class RequestMailerTest < ActionMailer::TestCase

  tests RequestMailer

  test "notification" do
    request = Request.create!(requests(:all_your_info).attributes)
    email = RequestMailer.notification(request).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match 'http://localhost:3000', email.body.to_s
  end

end
