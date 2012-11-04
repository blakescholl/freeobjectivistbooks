# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20121104215933) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "books", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.boolean  "featured"
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campaign_targets", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "group"
    t.string   "last_campaign"
    t.datetime "emailed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "donations", :force => true do |t|
    t.integer  "request_id"
    t.integer  "user_id"
    t.string   "status"
    t.boolean  "flagged",           :default => false, :null => false
    t.boolean  "thanked",           :default => false, :null => false
    t.boolean  "canceled",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "status_updated_at"
  end

  add_index "donations", ["request_id"], :name => "index_donations_on_request_id"
  add_index "donations", ["user_id"], :name => "index_donations_on_user_id"

  create_table "events", :force => true do |t|
    t.integer  "request_id"
    t.integer  "user_id"
    t.integer  "donor_id_deprecated"
    t.string   "type"
    t.string   "detail"
    t.text     "message"
    t.datetime "happened_at"
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public"
    t.boolean  "is_thanks"
    t.integer  "donation_id"
  end

  add_index "events", ["donation_id"], :name => "index_events_on_donation_id"
  add_index "events", ["donor_id_deprecated"], :name => "index_events_on_donor_id"
  add_index "events", ["request_id"], :name => "index_events_on_request_id"
  add_index "events", ["user_id"], :name => "index_events_on_user_id"

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.text     "geocoder_results"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["name"], :name => "index_locations_on_name"

  create_table "pledges", :force => true do |t|
    t.integer  "user_id"
    t.integer  "quantity"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "referral_id"
  end

  add_index "pledges", ["referral_id"], :name => "index_pledges_on_referral_id"
  add_index "pledges", ["user_id"], :name => "index_pledges_on_user_id"

  create_table "referrals", :force => true do |t|
    t.string   "source"
    t.string   "medium"
    t.text     "landing_url"
    t.text     "referring_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reminder_entities", :force => true do |t|
    t.integer  "reminder_id"
    t.integer  "entity_id"
    t.string   "entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reminder_entities", ["entity_id"], :name => "index_reminder_entities_on_entity_id"
  add_index "reminder_entities", ["entity_type"], :name => "index_reminder_entities_on_entity_type"
  add_index "reminder_entities", ["reminder_id"], :name => "index_reminder_entities_on_reminder_id"

  create_table "reminders", :force => true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.string   "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reminders", ["user_id"], :name => "index_reminders_on_user_id"

  create_table "requests", :force => true do |t|
    t.integer  "user_id"
    t.string   "book_deprecated"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "donor_id_deprecated"
    t.boolean  "flagged_deprecated"
    t.boolean  "thanked_deprecated"
    t.string   "status_deprecated"
    t.integer  "donation_id"
    t.integer  "referral_id"
    t.boolean  "canceled",            :default => false, :null => false
    t.datetime "open_at"
    t.integer  "book_id"
  end

  add_index "requests", ["donation_id"], :name => "index_requests_on_donation_id"
  add_index "requests", ["referral_id"], :name => "index_requests_on_referral_id"
  add_index "requests", ["user_id"], :name => "index_requests_on_user_id"

  create_table "reviews", :force => true do |t|
    t.integer  "user_id"
    t.string   "book_deprecated"
    t.text     "text"
    t.boolean  "recommend"
    t.integer  "donation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "book_id"
  end

  add_index "reviews", ["donation_id"], :name => "index_reviews_on_donation_id"
  add_index "reviews", ["user_id"], :name => "index_reviews_on_user_id"

  create_table "testimonials", :force => true do |t|
    t.string   "title"
    t.text     "text"
    t.string   "attribution"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id"
    t.string   "source_type"
    t.string   "type"
    t.float    "priority",    :default => 0.0, :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "location"
    t.string   "school"
    t.string   "studying"
    t.text     "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "referral_id"
  end

  add_index "users", ["referral_id"], :name => "index_users_on_referral_id"

end
