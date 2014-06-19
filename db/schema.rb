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

ActiveRecord::Schema.define(:version => 20140618163542) do

  create_table "acts_as_xapian_jobs", :force => true do |t|
    t.string  "model",    :null => false
    t.integer "model_id", :null => false
    t.string  "action",   :null => false
  end

  add_index "acts_as_xapian_jobs", ["model", "model_id"], :name => "index_acts_as_xapian_jobs_on_model_and_model_id", :unique => true

  create_table "alaveteli_feeds", :force => true do |t|
    t.integer  "last_event_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "attachments", :force => true do |t|
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "file",         :null => false
    t.text     "content_type", :null => false
    t.integer  "size",         :null => false
    t.string   "filename"
    t.integer  "response_id",  :null => false
  end

  create_table "confirmation_links", :force => true do |t|
    t.string   "token",                         :null => false
    t.integer  "request_id",                    :null => false
    t.boolean  "expired",    :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "lgcs_terms", :force => true do |t|
    t.string  "name",            :null => false
    t.integer "broader_term_id"
    t.text    "notes"
  end

  create_table "requestors", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "email"
    t.text     "notes"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "external_url"
  end

  create_table "requests", :force => true do |t|
    t.string   "title",                                        :null => false
    t.integer  "requestor_id",                                 :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.text     "body",                                         :null => false
    t.date     "date_received"
    t.date     "due_date",                                     :null => false
    t.integer  "lgcs_term_id"
    t.boolean  "is_published",              :default => true,  :null => false
    t.boolean  "is_requestor_name_visible", :default => false, :null => false
    t.string   "medium",                    :default => "web", :null => false
    t.integer  "remote_id"
    t.string   "remote_url"
    t.string   "state",                     :default => "new", :null => false
    t.string   "nondisclosure_reason"
    t.string   "remote_email"
    t.integer  "top_level_lgcs_term_id"
  end

  add_index "requests", ["due_date"], :name => "index_requests_on_due_date"
  add_index "requests", ["remote_id"], :name => "index_requests_on_remote_id"
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

end
