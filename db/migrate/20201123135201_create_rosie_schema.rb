class CreateRosieSchema < ActiveRecord::Migration[5.2]
  def up
    execute("CREATE SCHEMA rosie")
  end

  def down
    execute("DROP SCHEMA rosie CASCADE")
  end
end
