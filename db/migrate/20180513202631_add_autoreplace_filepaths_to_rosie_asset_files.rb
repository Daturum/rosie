class AddAutoreplaceFilepathsToRosieAssetFiles < ActiveRecord::Migration
  def change
    add_column :rosie_asset_files, :autoreplace_filepaths, :boolean
  end
end
