class CreateWorkoutRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :workout_records do |t|
      t.references :exercise, null: false, index: false, foreign_key: { on_delete: :restrict }
      t.date :performed_on, null: false
      t.decimal :weight, precision: 6, scale: 2, null: false
      t.integer :reps, :set_count, null: false
      t.timestamps null: false

      t.index [ :exercise_id, :performed_on ]
    end
  end
end
