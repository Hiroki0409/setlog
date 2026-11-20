class WorkoutRecord < ApplicationRecord
  MAX_WEIGHT = BigDecimal("9999.99")
  MAX_COUNT = 2_147_483_647
  WEIGHT_FORMAT = /\A[+-]?(?:[0-9]+(?:\.[0-9]{1,2})?|\.[0-9]{1,2})\z/
  DATE_FORMAT = /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/

  belongs_to :exercise

  validates :reps, :set_count, presence: true
  validates :reps, :set_count, numericality: {
    only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_COUNT
  }, allow_blank: true
  validate :validate_weight
  validate :validate_performed_on

  private

  def validate_weight
    input = weight_before_type_cast
    return errors.add(:weight, :blank) if input.blank?

    text = input.is_a?(BigDecimal) ? input.to_s("F") : input.to_s
    return if WEIGHT_FORMAT.match?(text) && BigDecimal(text).between?(0, MAX_WEIGHT)

    errors.add(:weight, :invalid)
  end

  def validate_performed_on
    input = performed_on_before_type_cast
    return errors.add(:performed_on, :blank) if input.blank?

    if input.is_a?(String) && !DATE_FORMAT.match?(input)
      return errors.add(:performed_on, :invalid)
    end

    date = performed_on
    errors.add(:performed_on, :invalid) unless date.is_a?(Date) && date.year.between?(1000, 9999)
  end
end
