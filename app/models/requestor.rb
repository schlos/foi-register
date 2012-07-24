# == Schema Information
#
# Table name: requestors
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_url :string(255)
#

class Requestor < ActiveRecord::Base
  has_many :requests
  
  def to_s
    "%s <%s>" % [name, email]
  end
end
