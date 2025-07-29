module Flow
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
              when :file
                Question::File
              else
                raise ArgumentError, "Unexpected answer_type for page #{page.id}: #{page.answer_type}"
              end
      klass.new({}, question_options(page, "en"))
    end

    def self.question_options(page, locale)
      hint_text = page.respond_to?(:hint_text) ? page.hint_text : nil

      { question_text: page.question_text(locale),
        hint_text:,
        is_optional: page.is_optional,
        answer_settings: page.answer_settings,
        page_heading: page.page_heading(locale),
        guidance_markdown: page.guidance_markdown(locale) }
    end
  end
end
