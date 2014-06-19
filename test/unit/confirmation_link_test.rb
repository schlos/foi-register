# == Schema Information
#
# Table name: confirmation_links
#
#  id            :integer          not null, primary key
#  token         :string           not null
#  request_id    :integer          not_null
#  expired       :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class ConfirmationLinkTest < ActiveSupport::TestCase
  test "initial values" do
    conf_link = ConfirmationLink.create(:request_id => 1)
    assert !conf_link.token.empty?
    assert_equal conf_link.expired, false
  end
end