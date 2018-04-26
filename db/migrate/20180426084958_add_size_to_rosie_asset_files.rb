class AddSizeToRosieAssetFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :rosie_asset_files, :size, :integer
  end
end
