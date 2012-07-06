class AttachmentsOnlyOnResponses < ActiveRecord::Migration
  def up
      add_column :attachments, :response_id, :integer
      execute "update attachments set response_id=request_or_response_id where request_or_response_type='response'"
      execute "delete from attachments where response_id is null"
      change_column_null :attachments, :response_id, false
      
      remove_column :attachments, :request_or_response_id
      remove_column :attachments, :request_or_response_type
  end

  def down
      add_column :attachments, :request_or_response_id
      add_column :attachments, :request_or_response_type
      execute "update attachments set request_or_response_id=response_id, request_or_response_type='response'"
      remove_column :attachments, :response_id
  end
end
