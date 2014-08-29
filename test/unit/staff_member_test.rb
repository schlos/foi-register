# == Schema Information
#
# Table name: staff_members
#
#  id              :integer          not null, primary key
#  email           :string(255)
#  password_digest :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class StaffMemberTest < ActiveSupport::TestCase
  test "password must be at least 8 characters" do
    user = StaffMember.new(:email => "me@here.com", :password => "3", :password_confirmation => "3")
    assert_equal false, user.valid?
    assert_equal 1, user.errors.messages.count
    assert_equal ["is too short (minimum is 8 characters)"], user.errors.messages[:password]
  end
end
