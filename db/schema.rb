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

ActiveRecord::Schema.define(version: 20160312232745) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "influences", force: :cascade do |t|
    t.text     "inf_type",    null: false
    t.integer  "user_id"
    t.integer  "post_id",     null: false
    t.integer  "from_inf_id"
    t.jsonb    "properties"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "influences", ["from_inf_id"], name: "index_influences_on_from_inf_id", using: :btree
  add_index "influences", ["inf_type", "post_id"], name: "index_influences_on_inf_type_and_post_id", using: :btree
  add_index "influences", ["inf_type"], name: "index_influences_on_inf_type", using: :btree
  add_index "influences", ["post_id"], name: "index_influences_on_post_id", using: :btree
  add_index "influences", ["user_id"], name: "index_influences_on_user_id", using: :btree

  create_table "posts", force: :cascade do |t|
    t.integer  "user_id"
    t.jsonb    "content"
    t.jsonb    "properties"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "total_reads",  default: 0, null: false
    t.integer  "total_shares", default: 0, null: false
  end

  add_index "posts", ["content"], name: "gin_index_posts_on_content", using: :gin
  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "user_relationships", force: :cascade do |t|
    t.integer  "follower_id", null: false
    t.integer  "follows_id",  null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_relationships", ["follower_id"], name: "index_user_relationships_on_follower_id", using: :btree
  add_index "user_relationships", ["follows_id"], name: "index_user_relationships_on_follows_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.text     "name",                              null: false
    t.text     "username",                          null: false
    t.text     "password_digest",                   null: false
    t.text     "token",                             null: false
    t.jsonb    "properties"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "total_read_influence",  default: 0, null: false
    t.integer  "total_share_influence", default: 0, null: false
    t.integer  "total_shares",          default: 0, null: false
    t.integer  "total_posts",           default: 0, null: false
  end

  add_index "users", ["name"], name: "gin_index_users_on_name", using: :gin
  add_index "users", ["token"], name: "index_users_on_token", using: :btree
  add_index "users", ["username"], name: "gin_index_users_on_username", using: :gin
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  add_foreign_key "influences", "influences", column: "from_inf_id"
  add_foreign_key "influences", "posts"
  add_foreign_key "influences", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "user_relationships", "users", column: "follower_id"
  add_foreign_key "user_relationships", "users", column: "follows_id"
end
