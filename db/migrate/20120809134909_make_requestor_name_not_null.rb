class MakeRequestorNameNotNull < ActiveRecord::Migration
  def up
    change_column_null(:requestors, :name, false)
  end

  def down
    change_column_null(:requestors, :name, true)
  end
end
