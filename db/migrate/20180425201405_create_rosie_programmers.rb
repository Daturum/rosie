class CreateRosieProgrammers < ActiveRecord::Migration[5.2]
  def change
    create_table :rosie_programmers do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
