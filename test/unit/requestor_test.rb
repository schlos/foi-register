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
end
