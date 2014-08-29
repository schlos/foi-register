# == Schema Information
#
# Table name: staff_members
#
#  id              :integer          not null, primary key
#  email           :string(255)
#  password_digest :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# A staff member, i.e. an employee of the public body who is
# authorised to interact with the application.

class StaffMember < ActiveRecord::Base
  has_secure_password

  attr_accessible :email, :password, :password_confirmation

  validates_presence_of :email
  validates_uniqueness_of :email
  validates :password, :length => { :minimum => 8 }

  def to_s
    email
  end
end
