class Question::NationalInsuranceNumber < Question::QuestionBase
  attribute :national_insurance_number
  validates :national_insurance_number, presence: true
end
