class ExercisesController < ApplicationController
  before_action :authenticate_user!

  def index
    @exercise = current_user.exercises.build
    @exercises = current_user.exercises.order(:id)
  end

  def create
    @exercise = current_user.exercises.build(exercise_params)
    return redirect_to exercises_path, status: :see_other if @exercise.save

    render_invalid_exercise
  rescue ActiveRecord::RecordNotUnique
    @exercise.errors.add(:name, :taken)
    render_invalid_exercise
  end

  private

  def exercise_params
    params.expect(exercise: [ :name ])
  end

  def render_invalid_exercise
    @exercises = current_user.exercises.order(:id)
    render :index, status: :unprocessable_content
  end
end
