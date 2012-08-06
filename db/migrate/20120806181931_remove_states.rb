class RemoveStates < ActiveRecord::Migration
  def up
    add_column :requests, :state, :string, :null => false, :default => 'new'
    execute %{
      update requests set state = coalesce(
        (
          select states.tag
          from request_states join states on (request_states.state_id = states.id)
          where request_states.request_id = requests.id
          and not exists (
            select *
            from request_states newer_rs
            where newer_rs.created_at > request_states.created_at
            and newer_rs.request_id = request_states.request_id
          )
        ),
        'new'
      )
    }
    add_column :requests, :nondisclosure_reason, :string, :null => true
    drop_table :states
    drop_table :request_states
  end

  def down
    create_table :states do |t|
      t.string :tag
      t.string :title
      t.string :description

      t.timestamps
    end
    create_table :request_states, :id => false do |t|
      t.integer :request_id
      t.integer :state_id
      t.text :note
      t.timestamps
    end
    add_index :request_states, [:request_id, :state_id]
    
    Request::REQUEST_STATES.each_pair do |tag, (title, description)|
      next if tag == "not_disclosed"
      State.create(:tag => tag, :title => title, :description => description)
    end
    Request::NONDISCLOSURE_REASONS.each_pair do |tag, (title, description)|
      State.create(:tag => "done_" + tag, :title => title, :description => description)
    end
    
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute %{
        insert into request_states (created_at, updated_at, request_id, state_id)
          select now(), now(), requests.id, states.id
          from requests, states
          where (
            requests.state <> 'not_disclosed'
            and states.tag = requests.state
          ) or (
            requests.state = 'not_disclosed'
            and states.tag = 'done_' || requests.nondisclosure_reason
          )
      }
    elsif ActiveRecord::Base.connection.adapter_name == "SQLite"
      execute %{
        insert into request_states (created_at, updated_at, request_id, state_id)
          select datetime(), datetime(), requests.id, states.id
          from requests, states
          where (
            requests.state <> 'not_disclosed'
            and states.tag = requests.state
          ) or (
            requests.state = 'not_disclosed'
            and states.tag = 'done_' || requests.nondisclosure_reason
          )
      }
    else
      raise "Unsupported database adapter"
    end
    
    remove_column :requests, :state
    remove_column :requests, :nondisclosure_reason
  end
end
