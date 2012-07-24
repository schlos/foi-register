# == Schema Information
#
# Table name: attachments
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  file         :string(255)      not null
#  content_type :text             not null
#  size         :integer          not null
#  filename     :string(255)
#  response_id  :integer          not null
#

require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
