class WorkoutRecordsController < ApplicationController
  before_action :authenticate_user!

  def new
    selection = params.permit(:exercise_id, :performed_on)
    @exercise = current_user.exercises.find(selection[:exercise_id])
    @workout_record = @exercise.workout_records.build(performed_on: selection[:performed_on])
  end

  def create
    attributes = workout_record_params
    @exercise = current_user.exercises.find(attributes.delete(:exercise_id))
    @workout_record = @exercise.workout_records.build(attributes)

    if @workout_record.save
      redirect_to new_workout_record_path(exercise_id: @exercise.id, performed_on: @workout_record.performed_on.iso8601),
                  notice: "記録を保存しました。", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def workout_record_params
    params.expect(workout_record: [ :exercise_id, :performed_on, :weight, :reps, :set_count ])
  end
end
