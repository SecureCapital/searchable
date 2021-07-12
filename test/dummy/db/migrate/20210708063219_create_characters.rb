class CreateCharacters < ActiveRecord::Migration[6.1]
  def change
    create_table :characters do |t|
      t.references :movie, index: true, null: false, foreign_key: {on_update: :cascade, on_delete: :cascade}
      t.references :actor, index: true, null: false, foreign_key: {on_update: :cascade, on_delete: :cascade}
      t.string :name
      t.timestamps
    end
  end
end
