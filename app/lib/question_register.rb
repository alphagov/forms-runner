class QuestionRegister
  def self.from_page(page)
    klass = case page.answer_type.to_sym
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
            when :long_text
              Question::LongText
            when :number
              Question::Number
            else
              raise ArgumentError, "Unexpected answer_type for page #{page.id}: #{page.answer_type}"
            end
    hint_text = page.respond_to?(:hint_text) ? page.hint_text : nil
    klass.new({}, { question_text: page.question_text, question_short_name: page.question_short_name, hint_text:, is_optional: page.is_optional })
  end
end
