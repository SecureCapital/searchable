class CreateRatings < ActiveRecord::Migration[6.1]
  def change
    create_table :ratings do |t|
      t.references :movie, index: true, null: false, foreign_key: {on_update: :cascade, on_delete: :cascade}
      t.integer :rate
      t.timestamps
    end
  end
end
