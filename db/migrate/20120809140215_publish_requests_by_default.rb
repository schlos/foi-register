class PublishRequestsByDefault < ActiveRecord::Migration
  def up
    change_column_default :requests, :is_published, true
  end

  def down
    change_column_default :requests, :is_published, false
  end
end
