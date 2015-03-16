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
  validate :email_address_format
  default_scope :order => 'created_at DESC'

  strip_attributes

  def email_address_format
    # may be null if requestorcreated manually by admin or
    # the external_url is populated
    errors.add(:email, "is invalid") if !email.blank? && email !~ /\A\S+@\S+\Z/
  end

  def to_s
    if !external_url.nil?
      %(<a href="#{external_url}">).html_safe + name + "</a>".html_safe
    elsif !email.nil? && !email.empty?
      "%s <%s>" % [name, email]
    else
      name
    end
  end

  class << self
    def find_by_external_url_scheme_insensitive(url)
      # Find a Requestor by their url, but in a URL scheme-insensitive way.
      instance = self.find_by_external_url(url)
      # check to see if there's an http or https equivalent
      # of the url before creating a new requestor
      if instance.nil?
        case url[0..4]
        when "http:"
          instance = self.find_by_external_url("https://#{url[7..-1]}")
        when "https"
          instance = self.find_by_external_url("http://#{url[8..-1]}")
        end
      end
      instance
    end
  end

end
