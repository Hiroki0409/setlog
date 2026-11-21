class WorkoutRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
    records = current_user.workout_records.includes(:exercise)
    @workout_records = records.order(performed_on: :desc, created_at: :desc, id: :desc).load

    selection = params.permit(:exercise_id, :performed_on)
    if selection[:exercise_id].present?
      @return_exercise = current_user.exercises.find_by(id: selection[:exercise_id])
      @return_date = selection[:performed_on]
    end
  end

  def new
    selection = params.permit(:exercise_id, :performed_on)
    @exercise = current_user.exercises.find(selection[:exercise_id])
    @workout_record = @exercise.workout_records.build(performed_on: selection[:performed_on])
    load_previous_workout
  end

  def create
    attributes = workout_record_params
    @exercise = current_user.exercises.find(attributes.delete(:exercise_id))
    @workout_record = @exercise.workout_records.build(attributes)

    if @workout_record.save
      redirect_to new_workout_record_path(exercise_id: @exercise.id, performed_on: @workout_record.performed_on.iso8601),
                  notice: "記録を保存しました。", status: :see_other
    else
      load_previous_workout
      render :new, status: :unprocessable_content
    end
  end

  private

  def load_previous_workout
    return unless @workout_record.valid_performed_on?

    @input_date = @workout_record.performed_on
    @previous_workout_records = @exercise.previous_workout_records(before: @input_date).to_a
  end

  def workout_record_params
    params.expect(workout_record: [ :exercise_id, :performed_on, :weight, :reps, :set_count ])
  end
end
