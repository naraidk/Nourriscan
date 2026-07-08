class CreateDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :dishes do |t|
      t.string :name
      t.integer :calories
      t.integer :proteins
      t.integer :carbs
      t.integer :fats
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
