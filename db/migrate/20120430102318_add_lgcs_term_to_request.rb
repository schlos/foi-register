class AddLgcsTermToRequest < ActiveRecord::Migration
  def up
    add_column :requests, :lgcs_term_id, :integer, :null => true
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # SQLite3 doesn’t support adding a foreign key constraint to an existing table
      execute "alter table requests add constraint requests_lgcs_term_fk foreign key (lgcs_term_id) references lgcs_terms(id)"
    end
  end
  
  def down
    remove_column :requests, :lgcs_term_id
  end
end
