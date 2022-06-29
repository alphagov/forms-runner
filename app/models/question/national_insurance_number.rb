class Question::NationalInsuranceNumber < Question::ApplicationQuestion
  attribute :national_insurance_number
  validates :national_insurance_number, presence: true
end
