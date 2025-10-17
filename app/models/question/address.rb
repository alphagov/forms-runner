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
    validate :international_address_valid?, if: :is_international_address?

    def postcode=(str)
      super str.present? ? UKPostcode.parse(str).to_s : str
    end

    def is_international_address?
      answer_settings.present? && answer_settings&.input_type&.international_address == "true"
    end

    def show_answer_in_json(*)
      if is_international_address?
        {
          "street_address" => street_address.to_s,
          "country" => country.to_s,
          "answer_text" => show_answer,
        }
      else
        {
          "address1" => address1.to_s,
          "address2" => address2.to_s,
          "town_or_city" => town_or_city.to_s,
          "county" => county.to_s,
          "postcode" => postcode.to_s,
          "answer_text" => show_answer,
        }
      end
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
      errors.add(:address1, :too_long) if address1.present? && address1.length > 499
      errors.add(:address2, :too_long) if address2.present? && address2.length > 499
      errors.add(:town_or_city, :blank) if town_or_city.blank?
      errors.add(:town_or_city, :too_long) if town_or_city.present? && town_or_city.length > 499
      errors.add(:county, :too_long) if county.present? && county.length > 499
      errors.add(:postcode, :blank) if postcode.blank?
      errors
    end

    def international_address_valid?
      return if skipping_question?

      errors.add(:street_address, :blank) if street_address.blank?
      errors.add(:street_address, :too_long) if street_address.present? && street_address.length > 4999
      errors.add(:country, :blank) if country.blank?
      errors.add(:country, :too_long) if country.present? && country.length > 499
      errors
    end
  end
end
