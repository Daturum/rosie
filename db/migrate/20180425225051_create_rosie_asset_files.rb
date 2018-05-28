class CreateRosieAssetFiles < ActiveRecord::Migration
  def change
    create_table :rosie_asset_files do |t|
      t.string :filename
      t.string :content_type
      t.binary :file_contents

      t.timestamps
    end
  end
end
