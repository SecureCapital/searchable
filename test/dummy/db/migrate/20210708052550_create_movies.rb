class CreateMovies < ActiveRecord::Migration[6.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :summary
      t.decimal :rental_price, :precision => 5, :scale => 2
      t.timestamps
    end
  end
end
