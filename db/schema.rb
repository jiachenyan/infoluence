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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160312050333) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "posts", force: :cascade do |t|
    t.integer  "user_id"
    t.jsonb    "content"
    t.jsonb    "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "posts", ["content"], name: "gin_index_posts_on_content", using: :gin
  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.text     "name",                null: false
    t.text     "username",            null: false
    t.text     "email",               null: false
    t.text     "password_digest",     null: false
    t.text     "token",               null: false
    t.integer  "total_influence",     null: false
    t.jsonb    "properties"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["name"], name: "gin_index_users_on_name", using: :gin
  add_index "users", ["token"], name: "index_users_on_token", using: :btree
  add_index "users", ["username"], name: "gin_index_users_on_username", using: :gin
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  add_foreign_key "posts", "users"
end