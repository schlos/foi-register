# == Schema Information
#
# Table name: request_states
#
#  request_id :integer
#  state_id   :integer
#  note       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RequestState < ActiveRecord::Base
  belongs_to :request
  belongs_to :state
end
