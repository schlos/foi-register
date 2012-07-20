class CreateLgcsTerms < ActiveRecord::Migration
  def up
    create_table :lgcs_terms do |t|
      t.string :name, :null => false
      t.integer :broader_term_id, :null => true # A reference to another term
    end
    
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # SQLite3 doesn’t support adding a foreign key constraint to an existing table
      execute "alter table lgcs_terms add constraint lgcs_terms_broader_term_fk foreign key (broader_term_id) references lgcs_terms(id)"
    end
  end
  
  def down
    drop_table :lgcs_terms
  end
end
