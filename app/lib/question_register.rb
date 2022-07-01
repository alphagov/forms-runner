require_relative "../../app/models/question/question_base"
require_relative "../../app/models/question/single_line"

class QuestionRegister
  def self.from_page(page)
    case page.answer_type.to_sym
    when :single_line
      Question::SingleLine
    when :date
      Question::Date
    when :address
      Question::Address
    when :email
      Question::Email
    when :national_insurance_number
      Question::NationalInsuranceNumber
    when :phone_number
      Question::PhoneNumber
    else
      raise ArgumentError, "Unexpected answer_type for page #{page.id}: #{page.answer_type}"
    end
  end
end
