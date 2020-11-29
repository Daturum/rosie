class CreateRosieAssetFiles < ActiveRecord::Migration[5.2]
  def change
    reversible do |r|
      r.up do
        execute("SET search_path TO rosie,public")
      end
      r.down do
        execute("SET search_path TO public")
      end
    end

    create_table :rosie_asset_files do |t|
      t.string :filename
      t.string :content_type
      t.binary :file_contents

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
