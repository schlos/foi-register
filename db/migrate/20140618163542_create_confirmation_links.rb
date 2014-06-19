class CreateConfirmationLinks < ActiveRecord::Migration
  def up
    create_table :confirmation_links, :force => true do |t|
      t.string  :token, :null => false
      t.integer :request_id, :null => false
      t.boolean :expired, :default => false
      t.timestamps
    end
  end

  def down
    drop_table :confirmation_links
  end
end