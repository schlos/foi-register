class AddTopLevelLgcsTermToRequest < ActiveRecord::Migration
  def up
    add_column :requests, :top_level_lgcs_term_id, :integer

    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # SQLite3 doesn’t support adding a constraint to an existing table
      execute "alter table requests add constraint requests_top_level_lgcs_term_fk foreign key (top_level_lgcs_term_id) references lgcs_terms(id)"
    end
    
    Request.find_each do |request|
      request.save  # Invokes the before_save method set_top_level_lgcs_term
    end
    
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "alter table requests add constraint requests_lgcs_term_ck check ((lgcs_term_id is null) = (top_level_lgcs_term_id is null))"
    end
  end
  
  def down
    remove_column :requests, :top_level_lgcs_term_id
  end
end
