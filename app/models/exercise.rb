class Exercise < ApplicationRecord
  belongs_to :user
  has_many :workout_records

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id }
end
