class AddContextToRosieAssetFiles < ActiveRecord::Migration[5.2]
  def change
    add_column 'rosie.rosie_asset_files', :file_use_case, :string
  end
end
