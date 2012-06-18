# == Schema Information
#
# Table name: responses
#
#  id           :integer         not null, primary key
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  private_part :text            not null
#  public_part  :text            not null
#  request_id   :integer         not null
#

class Response < ActiveRecord::Base
  belongs_to :request
  has_many :attachments, :as => :request_or_response
  accepts_nested_attributes_for :attachments
  accepts_nested_attributes_for :request

  acts_as_xapian({
    :texts => [ :private_part, :public_part ],
    :values => [
        [ :created_at, 0, "created_at", :date ]
    ],
    :terms => [
        [ :request_id, 'R', "request_id" ]
    ]})

  def request_attributes=(attributes)
    # process an attributes hash passed from nested form field
    request = Request.find(attributes[:id])
    request.state = State.find(attributes[:state_attributes][:id])
  end

end
