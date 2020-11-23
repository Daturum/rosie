class CreateRosieProgrammers < ActiveRecord::Migration[5.2]
  def change
    reversible do |r|
      r.up do
        execute("SET search_path TO rosie,public")
      end
      r.down do
        execute("SET search_path TO public")
      end
    end

    create_table :rosie_programmers do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end

    reversible do |r|
      r.up do
        execute("SET search_path TO public")
      end
      r.down do
        execute("SET search_path TO rosie,public")
      end
    end
  end
end
