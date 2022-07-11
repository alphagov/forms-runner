class Question::PhoneNumber < Question::QuestionBase
  # https://design-system.service.gov.uk/patterns/telephone-numbers/
  # Allow a large range of values - we would probably need more information to
  # provide better validation - e.g. UK or international number
  # We check the characters and that the number is in a reasonable range
  # some code and tests inspired by git@github.com:DFE-Digital/apply-for-teacher-training.git

  PHONE_REGEX = /\A[ext\-()+.\s 0-9]+\z/
  attribute :phone_number
  validates :phone_number, presence: true
  validates :phone_number, format: { with: PHONE_REGEX, message: "Enter a telephone number" }, allow_blank: true
  validate :phone_number, :not_enough_digits?
  validate :phone_number, :too_many_digits?

private

  def not_enough_digits?
    if phone_number.present? && phone_number.gsub(/[^0-9]/, "").length < 8
      errors.add(:phone_number, :phone_too_short)
    end
  end

  def too_many_digits?
    if phone_number.present? && phone_number.gsub(/[^0-9]/, "").length > 15
      errors.add(:phone_number, :phone_too_long)
    end
  end
end
