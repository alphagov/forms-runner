class Question::NationalInsuranceNumber
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization

  attr_accessor :national_insurance_number

  validates :national_insurance_number, presence: true

  def attributes
    { "national_insurance_number" => nil }
  end

  def value
    national_insurance_number
  end
end
