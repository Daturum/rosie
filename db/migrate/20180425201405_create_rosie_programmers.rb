class CreateRosieProgrammers < ActiveRecord::Migration
  def change
    create_table :rosie_programmers do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
