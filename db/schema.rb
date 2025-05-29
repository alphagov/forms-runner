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

ActiveRecord::Schema[8.0].define(version: 2025_05_29_084029) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference"
    t.string "mail_message_id"
    t.integer "form_id"
    t.jsonb "answers"
    t.string "mode"
    t.jsonb "form_document"
    t.string "mail_status", default: "pending", null: false
    t.datetime "sent_at"
    t.index ["mail_message_id"], name: "index_submissions_on_mail_message_id"
    t.index ["sent_at"], name: "index_submissions_on_sent_at"
  end
end
