# == Schema Information
#
# Table name: attachments
#
#  id           :integer         not null, primary key
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  file         :string(255)     not null
#  content_type :text            not null
#  size         :integer         not null
#  filename     :string(255)
#  response_id  :integer         not null
#

class Attachment < ActiveRecord::Base
  mount_uploader :file, AttachmentUploader
  belongs_to :response
  before_save :update_metadata
  
  private
  def update_metadata
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.size = file.file.size
      self.filename = file.file.filename
    end
  end
end
