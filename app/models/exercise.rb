class Exercise < ApplicationRecord
  belongs_to :user
  has_many :workout_records

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id }

  def previous_workout_records(before:)
    earlier_records = workout_records.where("performed_on < ?", before)
    previous_date = earlier_records.select("MAX(performed_on)")

    workout_records.where(performed_on: previous_date).order(:created_at, :id)
  end
end
