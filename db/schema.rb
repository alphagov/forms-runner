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

ActiveRecord::Schema[8.1].define(version: 2026_02_02_173033) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "delivery_reference"
    t.datetime "failed_at"
    t.string "failure_reason"
    t.datetime "last_attempt_at"
    t.datetime "updated_at", null: false
    t.index ["delivery_reference"], name: "index_deliveries_on_delivery_reference"
  end

  create_table "submission_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "delivery_id", null: false
    t.bigint "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_submission_deliveries_on_delivery_id"
    t.index ["submission_id"], name: "index_submission_deliveries_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.jsonb "answers"
    t.datetime "bounced_at"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "delivery_status", default: "pending", null: false
    t.jsonb "form_document"
    t.integer "form_id"
    t.datetime "last_delivery_attempt"
    t.string "mail_message_id"
    t.string "mode"
    t.string "reference"
    t.string "submission_locale", default: "en", null: false, comment: "The language the form was submitted in ISO 2 letter format. Normally either 'en' or 'cy'"
    t.datetime "updated_at", null: false
    t.index ["last_delivery_attempt"], name: "index_submissions_on_last_delivery_attempt"
    t.index ["mail_message_id"], name: "index_submissions_on_mail_message_id"
  end

  add_foreign_key "submission_deliveries", "deliveries"
  add_foreign_key "submission_deliveries", "submissions"
end
