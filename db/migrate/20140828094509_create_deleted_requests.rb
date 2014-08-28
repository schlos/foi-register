class CreateDeletedRequests < ActiveRecord::Migration
  def change
    create_table :deleted_requests do |t|
      t.string :title,  :null => false
      t.integer :requestor_id, :null => false
      t.text :body,     :null => false
      t.date :date_received
      t.date :due_date, :null => false
      t.integer :lgcs_term_id
      t.boolean :is_published, :default => true, :null => false
      t.boolean :is_requestor_name_visible, :default => true, :null => false
      t.string  :medium, :default => "web", :null => false
      t.integer :remote_id
      t.string  :remote_url
      t.string  :state, :default => "new", :null => false
      t.string  :nondisclosure_reason
      t.string  :remote_email
      t.integer :top_level_lgcs_term_id
      t.integer :request_id, :null => false
      t.string  :deleted_by
      t.date    :deleted_date, :null => false

      t.timestamps
    end
  end
end
