class CreateSearchableIndices < ActiveRecord::Migration[6.1]
  def up
    create_table :searchable_indices do |t|
      t.string     :owner_type, null: false
      t.integer    :owner_id,   null: false
      t.text       :searchable, limit: 5000
      t.timestamps
      t.index :owner_type
      t.index :owner_id
      t.index [:owner_type,:owner_id], unique: true
    end
  end

  def down
    drop_table :searchable_indices
  end
end
