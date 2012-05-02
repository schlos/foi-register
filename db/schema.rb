# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120502131008) do

  create_table "attachments", :force => true do |t|
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "file",                     :null => false
    t.text     "content_type",             :null => false
    t.integer  "size",                     :null => false
    t.integer  "request_or_response_id"
    t.string   "request_or_response_type"
    t.string   "filename"
  end

  create_table "lgcs_terms", :force => true do |t|
    t.string  "name",            :null => false
    t.integer "broader_term_id"
    t.text    "notes"
  end

  create_table "request_states", :id => false, :force => true do |t|
    t.integer  "request_id"
    t.integer  "state_id"
    t.text     "note"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "request_states", ["request_id", "state_id"], :name => "index_request_states_on_request_id_and_state_id"

  create_table "requestors", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.text     "notes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "requests", :force => true do |t|
    t.string   "title"
    t.string   "status"
    t.integer  "requestor_id"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.text     "body"
    t.date     "date_received"
    t.date     "due_date",                                     :null => false
    t.integer  "lgcs_term_id"
    t.boolean  "is_published",              :default => false, :null => false
    t.boolean  "is_requestor_name_visible", :default => false, :null => false
    t.string   "medium",                    :default => "web", :null => false
  end

  add_index "requests", ["due_date"], :name => "index_requests_on_due_date"
  add_index "requests", ["requestor_id"], :name => "index_requests_on_requestor_id"

  create_table "responses", :force => true do |t|
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.text     "private_part", :null => false
    t.text     "public_part",  :null => false
    t.integer  "request_id",   :null => false
  end

  create_table "staff_members", :force => true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "states", :force => true do |t|
    t.string   "tag"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

end
