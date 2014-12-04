class AddDefaultToResponsePrivatePart < ActiveRecord::Migration
  def change
    change_column :responses, :private_part, :text, :default => ""
  end
end