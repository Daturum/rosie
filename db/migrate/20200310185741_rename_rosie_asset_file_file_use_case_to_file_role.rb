class RenameRosieAssetFileFileUseCaseToFileRole < ActiveRecord::Migration[5.2]
  def change
    rename_column 'rosie.rosie_asset_files', :file_use_case, :file_role
  end
end
