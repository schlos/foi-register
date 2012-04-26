# == Schema Information
#
# Table name: requests
#
#  id            :integer         not null, primary key
#  title         :string(255)
#  status        :string(255)
#  requestor_id  :integer
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#  body          :text
#  date_received :date            default(Tue, 24 Apr 2012), not null
#

class Request < ActiveRecord::Base
  belongs_to :requestor
  validates_presence_of :title
  has_many :request_states
  has_many :states, :through => :request_states, :order => :created_at
  accepts_nested_attributes_for :requestor

  def state
    self.states.last || State.new
  end

  def state=(state)
    self.states << state
  end
 
  def state_attributes=(attributes)
    # process an attributes hash passed from nested form field
    self.state = State.find(attributes[:id])
  end

end
