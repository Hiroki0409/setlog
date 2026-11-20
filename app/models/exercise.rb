class Exercise < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id }
end
