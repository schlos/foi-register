# == Schema Information
#
# Table name: states
#
#  id          :integer          not null, primary key
#  tag         :string(255)
#  title       :string(255)
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class StateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
