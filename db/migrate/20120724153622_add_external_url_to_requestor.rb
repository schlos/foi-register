class AddExternalUrlToRequestor < ActiveRecord::Migration
  def change
    add_column :requestors, :external_url, :string
  end
end
