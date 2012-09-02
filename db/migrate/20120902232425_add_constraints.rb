class AddConstraints < ActiveRecord::Migration
  def up
    execute "delete from requests where title is null or body is null"
    change_column_null(:requests, :title, false)
    change_column_null(:requests, :body, false)
    
    execute "delete from requests where requestor_id is null or requestor_id not in (select id from requestors)"
    change_column_null(:requests, :requestor_id, false)
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # SQLite3 doesn’t support adding a foreign key constraint to an existing table
      execute "alter table requests add constraint requests_requestor_fk foreign key (requestor_id) references requestors(id)"
    end
  end

  def down
    change_column_null(:requests, :title, true)
    change_column_null(:requests, :requestor_id, true)
    change_column_null(:requests, :body, true)
    
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "alter table requests drop constraint requests_requestor_fk"
    end
  end
end
