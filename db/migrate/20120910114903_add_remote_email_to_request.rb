class AddRemoteEmailToRequest < ActiveRecord::Migration
  def change
    change_table :requests do |t|
      t.string :remote_email
    end
  end
end
