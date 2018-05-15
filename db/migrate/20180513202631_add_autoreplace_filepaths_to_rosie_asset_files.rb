class AddAutoreplaceFilepathsToRosieAssetFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :rosie_asset_files, :autoreplace_filepaths, :boolean
  end
end
