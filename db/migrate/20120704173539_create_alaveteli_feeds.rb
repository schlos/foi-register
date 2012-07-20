class CreateAlaveteliFeeds < ActiveRecord::Migration
  def change
    create_table :alaveteli_feeds do |t|
      t.integer :last_event_id, :null => false

      t.timestamps
    end
  end
end
