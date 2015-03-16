# == Schema Information
#
# Table name: requestors
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_url :string(255)
#

require 'test_helper'

class RequestorTest < ActiveSupport::TestCase
  test "should have a validation error if email is in the wrong format" do
    requestor = Requestor.new(:name => "Dave", :email => "invalid")
    assert_equal(false, requestor.save)
    assert_equal(1, requestor.errors.count)
  end

  test 'should strip a blank email address to nil' do
    requestor = Requestor.new(:name => "Dave", :email => "")
    requestor.save
    assert_equal(nil, requestor.email)
  end

  test 'find_by_external_url_scheme_insensitive should find with http or https url' do
    external_user = requestors(:external_user)
    external_url_http = "http://www.whatdotheyknow.com/users/test"
    external_url_https = "https://www.whatdotheyknow.com/users/test"
    assert_equal(Requestor.find_by_external_url_scheme_insensitive(external_url_http), external_user)
    assert_equal(Requestor.find_by_external_url_scheme_insensitive(external_url_https), external_user)
  end
end
