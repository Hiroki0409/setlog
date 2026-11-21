class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable

  has_many :exercises
  has_many :workout_records, through: :exercises
end
