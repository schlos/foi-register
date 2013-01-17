# == Schema Information
#
# Table name: responses
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  private_part :text             not null
#  public_part  :text             not null
#  request_id   :integer          not null
#

class Response < ActiveRecord::Base
  belongs_to :request
  has_many :attachments
  accepts_nested_attributes_for :attachments
  accepts_nested_attributes_for :request
  validates_presence_of :public_part

  acts_as_xapian({
    :texts => [ :public_part ],
    :values => [
        [ :created_at, 0, "created_at", :date ]
    ],
    :terms => [
        [ :private_part, 'P', 'private_part'],
        [ :request_id, 'R', "request_id" ]
    ]})

  def send_to_alaveteli
      AlaveteliApi.send_response(self) if request.remote_id
  end

  def send_by_email
    ResponseMailer.email_response(self).deliver if !request.email_for_response.nil?
  end

  handle_asynchronously :send_to_alaveteli

end
