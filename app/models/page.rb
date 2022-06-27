class Page < ActiveResource::Base
  self.site = ENV.fetch("API_BASE").to_s
  self.prefix = "/api/v1/forms/:form_id/"
  self.include_format_in_path = false

  belongs_to :form

  def form_id
    @prefix_options[:form_id]
  end

  def has_next?
    @attributes.include?("next") && !@attributes["next"].nil?
  end

  def question
    case answer_type.to_sym
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
      raise ArgumentError, "Unexpected answer_type: #{answer_type}"
    end
  end
end
