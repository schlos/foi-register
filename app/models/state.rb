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

class State < ActiveRecord::Base
  has_many :request_states
  has_many :requests, :through => :request_states
end
