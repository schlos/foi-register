class AddRemoteUrlToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :remote_url, :string

  end
end
