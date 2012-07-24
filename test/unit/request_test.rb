# == Schema Information
#
# Table name: requests
#
#  id                        :integer          not null, primary key
#  title                     :string(255)
#  requestor_id              :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  body                      :text
#  date_received             :date
#  due_date                  :date             not null
#  lgcs_term_id              :integer
#  is_published              :boolean          default(FALSE), not null
#  is_requestor_name_visible :boolean          default(FALSE), not null
#  medium                    :string(255)      default("web"), not null
#  remote_id                 :integer
#

require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
