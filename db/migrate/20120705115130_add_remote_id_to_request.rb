class AddRemoteIdToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :remote_id, :integer
    add_index :requests, :remote_id

  end
end
