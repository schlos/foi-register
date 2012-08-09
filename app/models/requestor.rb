# == Schema Information
#
# Table name: requestors
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_url :string(255)
#

class Requestor < ActiveRecord::Base
  has_many :requests
  validates_presence_of :name
  
  def to_s
    if !external_url.nil?
      %(<a href="#{external_url}">).html_safe + name + "</a>".html_safe
    elsif !email.nil? && !email.empty?
      "%s <%s>" % [name, email]
    else
      name
    end
  end
end
