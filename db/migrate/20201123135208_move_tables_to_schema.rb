class MoveTablesToSchema < ActiveRecord::Migration[5.2]
  def up
    sql = <<-SQL
INSERT INTO "rosie"."versions"(item_type, item_id, event, whodunnit, object, created_at)
  SELECT item_type, item_id, event, whodunnit, object, created_at FROM "public"."versions"
  WHERE item_type ILIKE 'Rosie::%'
    SQL
    execute(sql)

    sql = <<-SQL
DELETE FROM "public"."versions" WHERE item_type ILIKE 'Rosie::%'
    SQL

    execute(sql)
  end

  def down
  end
end
