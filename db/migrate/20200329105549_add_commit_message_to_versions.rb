class AddCommitMessageToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column 'rosie.versions', :commit_message, :string
  end
end
