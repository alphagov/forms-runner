module Question
  class NationalInsuranceNumber < Question::QuestionBase
    # see https://design-system.service.gov.uk/patterns/national-insurance-numbers/
    NINO_REGEX = /\A(?!BG|GB|NK|KN|TN|NT|ZZ)[ABCEGHJ-PRSTW-Z][ABCEGHJ-NPRSTW-Z]\d{6}[A-D]\z/i

    include ActiveModel::Validations::Callbacks

    attribute :national_insurance_number
    validates :national_insurance_number, presence: true
    # validates :national_insurance_number, format: { with: NINO_REGEX, message: :invalid_national_insurance_number }, allow_blank: true
    validate :valid_format

    def show_answer
      # format the NINO in the correct govuk format
      # show NINOs in the form of "QQ 12 34 56 C"
      return "" if national_insurance_number.blank?

      nino = normalize_nino(national_insurance_number)
      nino.blank? ? "" : "#{nino[0..1]} #{nino[2..3]} #{nino[4..5]} #{nino[6..7]} #{nino[8]}"
    end

  private

    def valid_format
      return if national_insurance_number.blank?

      unless NINO_REGEX.match(normalize_nino(national_insurance_number))
        errors.add(:national_insurance_number, :invalid_national_insurance_number)
      end
    end

    def normalize_nino(nino)
      nino.gsub(/\s/, "").upcase
    end
  end
end
