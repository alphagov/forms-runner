class QuestionRegister
  def self.from_page(page)
    klass = case page.answer_type.to_sym
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
            when :number
              Question::Number
            when :selection
              Question::Selection
            when :organisation_name
              Question::OrganisationName
            when :text
              Question::Text
            when :name
              Question::Name
            else
              raise ArgumentError, "Unexpected answer_type for page #{page.id}: #{page.answer_type}"
            end
    hint_text = page.respond_to?(:hint_text) ? page.hint_text : nil
    page_heading = page.respond_to?(:page_heading) ? page.page_heading : nil
    guidance_markdown = page.respond_to?(:guidance_markdown) ? page.guidance_markdown : nil
    klass.new({}, { question_text: page.question_text,
                    hint_text:,
                    is_optional: page.is_optional,
                    answer_settings: page.answer_settings,
                    page_heading:,
                    guidance_markdown: })
  end
end
