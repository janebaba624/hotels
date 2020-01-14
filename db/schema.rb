# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_29_071038) do

  create_table "bookings", force: :cascade do |t|
    t.datetime "dtstart"
    t.datetime "dtend"
    t.string "summary"
    t.text "description"
    t.string "status"
    t.integer "user_id"
    t.integer "house_id"
    t.integer "room_id"
    t.integer "room_unit_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["house_id"], name: "index_bookings_on_house_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["room_unit_id"], name: "index_bookings_on_room_unit_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "houses", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "status"
    t.boolean "is_master"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "room_units", force: :cascade do |t|
    t.string "room_no"
    t.integer "room_id"
    t.integer "house_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "part_of_room_id"
    t.index ["house_id"], name: "index_room_units_on_house_id"
    t.index ["room_id"], name: "index_room_units_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.boolean "is_master"
    t.integer "house_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["house_id"], name: "index_rooms_on_house_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
