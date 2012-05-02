class AddMediumToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :medium, :string, :null => false, :default => "web"
  end
end
