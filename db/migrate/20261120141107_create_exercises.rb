class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :restrict }
      t.string :name, limit: 100, null: false
      t.timestamps null: false

      t.index [ :user_id, :name ], unique: true
    end
  end
end
