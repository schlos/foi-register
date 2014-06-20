class AddRequestorStateToRequest < ActiveRecord::Migration
  def change
    change_table :requests do |t|
      t.string :requestor_state
    end
  end
end
