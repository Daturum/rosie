class CreateRosieComponents < ActiveRecord::Migration
  def change
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
  end
end
