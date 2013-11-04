require 'test_helper'

class RequestMailerTest < ActionMailer::TestCase
  tests RequestMailer

  setup do
    Rails.configuration.action_mailer.default_url_options = {:host => "www.example.org"}
  end

  test "notification" do
    request = Request.create!(requests(:all_your_info).attributes)
    email = RequestMailer.notification(request).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match 'http://www.example.org', email.body.to_s
  end
end
