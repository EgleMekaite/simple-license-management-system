# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_07_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "license_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.uuid "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "product_id"], name: "index_license_assignments_on_account_and_product"
    t.index ["account_id", "user_id", "product_id"], name: "index_license_assignments_on_account_user_product", unique: true
    t.index ["account_id"], name: "index_license_assignments_on_account_id"
    t.index ["product_id"], name: "index_license_assignments_on_product_id"
    t.index ["user_id"], name: "index_license_assignments_on_user_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "product_id", null: false
    t.integer "number_of_licenses", default: 0, null: false
    t.datetime "issued_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "product_id"], name: "index_subscriptions_on_account_id_and_product_id", unique: true
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["product_id"], name: "index_subscriptions_on_product_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["account_id", "name"], name: "index_users_on_account_id_and_name"
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "license_assignments", "accounts"
  add_foreign_key "license_assignments", "products"
  add_foreign_key "license_assignments", "users"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "products"
  add_foreign_key "users", "accounts"
end
