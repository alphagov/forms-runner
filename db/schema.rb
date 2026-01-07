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

ActiveRecord::Schema[8.1].define(version: 2025_11_20_114903) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.datetime "updated_at", null: false
    t.index ["last_delivery_attempt"], name: "index_submissions_on_last_delivery_attempt"
    t.index ["mail_message_id"], name: "index_submissions_on_mail_message_id"
  end
end
