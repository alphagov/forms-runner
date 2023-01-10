module Question
  class Address < Question::QuestionBase
    # https://design-system.service.gov.uk/patterns/addresses/
    attribute :address1
    attribute :address2
    attribute :town_or_city
    attribute :county
    attribute :postcode
    attribute :street_address
    attribute :country

    validate :uk_address_valid?, unless: :is_international_address?
    validate :postcode, :invalid_postcode?, unless: :is_international_address?
    validate :international_adress_valid?, if: :is_international_address?

    def postcode=(str)
      super str.present? ? UKPostcode.parse(str).to_s : str
    end

    def is_international_address?
      answer_settings.present? && answer_settings&.input_type&.international_address == "true"
    end

  private

    def invalid_postcode?
      if postcode.present?
        ukpc = UKPostcode.parse(postcode)
        unless ukpc.full_valid?
          errors.add(:postcode, :invalid_postcode)
        end
      end
    end

    def skipping_question?
      fields = [address1, address2, town_or_city, county, postcode, street_address, country]
      is_optional? && fields.none?(&:present?)
    end

    def uk_address_valid?
      return if skipping_question?

      errors.add(:address1, :blank) if address1.blank?
      errors.add(:town_or_city, :blank) if town_or_city.blank?
      errors.add(:postcode, :blank) if postcode.blank?
      errors
    end

    def international_adress_valid?
      return if skipping_question?

      errors.add(:street_address, :blank) if street_address.blank?
      errors.add(:country, :blank) if country.blank?
      errors
    end
  end
end
