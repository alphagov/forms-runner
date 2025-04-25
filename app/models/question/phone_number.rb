module Question
  class PhoneNumber < Question::QuestionBase
    # https://design-system.service.gov.uk/patterns/telephone-numbers/
    # Allow a large range of values - we would probably need more information to
    # provide better validation - e.g. UK or international number
    # We check the characters and that the number is in a reasonable range
    # some code and tests inspired by https://github.com/DFE-Digital/apply-for-teacher-training

    PHONE_REGEX = /\A[ext\-()+.\s 0-9]+\z/
    attribute :phone_number
    validates :phone_number, presence: true, unless: :is_optional?
    validates :phone_number, format: { with: PHONE_REGEX, message: :invalid_phone_number }, allow_blank: true
    validate :phone_number, :not_enough_digits?
    validate :phone_number, :too_many_digits?

    def show_answer_in_csv(*)
      return { question_text => "" } if phone_number.blank?
      # numbers containing non-numeric characters, or starting with a non-0 digit, shouldn't need additional processing
      return { question_text => phone_number } unless phone_number.match(/^0\d*$/)

      # insert a space after the first 5 digits to force Excel to parse the phone number as a string
      { question_text => phone_number.gsub(/(^\d{5})(\d*)$/, "\\1 \\2") }
    end

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
end
