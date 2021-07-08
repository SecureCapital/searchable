class DropSearchableIndices < ActiveRecord::Migration<%=migration_version%>
  def up
    drop_table :searchable_indices
  end

  def down
    create_table :searchable_indices do |t|
      t.string     :owner_type, null: false
      t.integer    :owner_id,   null: false
      t.text       :searchable
      t.timestamps
      t.index :owner_type
      t.index :owner_id
      t.index [:owner_type,:owner_id], unique: true
    end
  end
end
