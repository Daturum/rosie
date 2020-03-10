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

ActiveRecord::Schema.define(version: 2020_03_10_185741) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "rosie_flat", force: :cascade do |t|
    t.decimal "square"
    t.decimal "total_price"
    t.decimal "sqmeter_price"
    t.string "address"
    t.string "category"
    t.string "telephones"
    t.string "description"
    t.string "cottage_name"
    t.string "additional"
    t.string "link"
    t.integer "cian_id"
    t.boolean "previous_dataset"
    t.text "previous_change_signal"
    t.string "rooms"
    t.index ["address"], name: "index_rosie_flat_on_address"
    t.index ["category"], name: "index_rosie_flat_on_category"
    t.index ["cian_id"], name: "index_rosie_flat_on_cian_id"
    t.index ["cottage_name"], name: "index_rosie_flat_on_cottage_name"
    t.index ["sqmeter_price"], name: "index_rosie_flat_on_sqmeter_price"
    t.index ["square"], name: "index_rosie_flat_on_square"
    t.index ["total_price"], name: "index_rosie_flat_on_total_price"
  end

  create_table "rosie_flat_search", force: :cascade do |t|
    t.string "name"
    t.string "link"
    t.integer "mindiscount"
    t.integer "minprice"
    t.integer "maxprice"
    t.integer "minsquare"
    t.text "result"
    t.integer "record_count"
    t.integer "interesting_count"
    t.string "grouping_rules"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary "excels_zip"
    t.integer "previous_change_signals"
    t.index ["name"], name: "index_rosie_flat_search_on_name"
  end

  create_table "rosie_prop_search", force: :cascade do |t|
    t.string "name"
    t.string "link"
    t.text "result"
    t.integer "record_count"
    t.integer "interesting_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary "excels_zip"
    t.integer "mindiscount"
    t.integer "minprice"
    t.integer "maxprice"
    t.integer "minsotka"
    t.string "grouping_rules"
    t.integer "previous_change_signals"
    t.index ["name"], name: "index_rosie_prop_search_on_name"
  end

  create_table "rosie_user_properties", force: :cascade do |t|
    t.decimal "square"
    t.decimal "total_price"
    t.decimal "sotka_price"
    t.string "address"
    t.string "category"
    t.string "telephones"
    t.string "description"
    t.string "cottage_name"
    t.string "additional"
    t.string "link"
    t.integer "cian_id"
    t.boolean "previous_dataset"
    t.text "previous_change_signal"
    t.index ["address"], name: "index_rosie_user_properties_on_address"
    t.index ["category"], name: "index_rosie_user_properties_on_category"
    t.index ["cian_id"], name: "index_rosie_user_properties_on_cian_id"
    t.index ["cottage_name"], name: "index_rosie_user_properties_on_cottage_name"
    t.index ["sotka_price"], name: "index_rosie_user_properties_on_sotka_price"
    t.index ["square"], name: "index_rosie_user_properties_on_square"
    t.index ["total_price"], name: "index_rosie_user_properties_on_total_price"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
