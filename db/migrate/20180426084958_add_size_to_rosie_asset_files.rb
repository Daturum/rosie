class AddSizeToRosieAssetFiles < ActiveRecord::Migration
  def change
    add_column :rosie_asset_files, :size, :integer
  end
end
