class MoveTablesToSchema < ActiveRecord::Migration[5.2]
  TABLES = %w(rosie_programmers rosie_asset_files rosie_components)

  def up
    TABLES.each do |table|
      execute("ALTER TABLE IF EXISTS #{table} SET SCHEMA rosie")
    end

    execute("SET search_path TO rosie,public")
    create_table :versions do |t|
      t.string   :item_type, {:null=>false}
      t.integer  :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.jsonb     :object

      # Known issue in MySQL: fractional second precision
      # -------------------------------------------------
      #
      # MySQL timestamp columns do not support fractional seconds unless
      # defined with "fractional seconds precision". MySQL users should manually
      # add fractional seconds precision to this migration, specifically, to
      # the `created_at` column.
      # (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
      #
      # MySQL users should also upgrade to rails 4.2, which is the first
      # version of ActiveRecord with support for fractional seconds in MySQL.
      # (https://github.com/rails/rails/pull/14359)
      #
      t.datetime :created_at
    end

    sql = <<-SQL
INSERT INTO "rosie"."versions"(item_type, item_id, event, whodunnit, object, created_at)
  SELECT item_type, item_id, event, whodunnit, object::jsonb, created_at FROM "public"."versions" 
  WHERE item_type ILIKE 'Rosie::%'
    SQL
    execute(sql)

    sql = <<-SQL
DELETE FROM "public"."versions" WHERE item_type ILIKE 'Rosie::%'
    SQL

    execute(sql)

    execute("SET search_path TO public")
  end

  def down
  end
end
