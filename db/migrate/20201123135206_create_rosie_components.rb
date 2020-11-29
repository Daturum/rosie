class CreateRosieComponents < ActiveRecord::Migration[5.2]
  def change
    reversible do |r|
      r.up do
        execute("SET search_path TO rosie,public")
      end
      r.down do
        execute("SET search_path TO public")
      end
    end

    create_table :rosie_components do |t|
      t.string :component_type
      t.string :path
      t.string :locale
      t.string :handler
      t.boolean :partial
      t.string :format
      t.string :editing_locked_by
      t.text :body
      t.text :loading_error

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
