class CreateActors < ActiveRecord::Migration[6.1]
  def change
    create_table :actors do |t|
      t.string :name
      t.text :bio
      t.date :birthday
      t.timestamps
    end
  end
end
