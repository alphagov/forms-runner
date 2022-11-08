module Question
  class Address < Question::QuestionBase
    # https://design-system.service.gov.uk/patterns/addresses/
    attribute :address1
    attribute :address2
    attribute :town_or_city
    attribute :county
    attribute :postcode

    validates :address1, presence: true, unless: :skipping_question?
    validates :town_or_city, presence: true, unless: :skipping_question?
    validates :postcode, presence: true, unless: :skipping_question?
    validate :postcode, :invalid_postcode?

    def postcode=(str)
      super UKPostcode.parse(str).to_s
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
      fields = [address1, address2, town_or_city, county, postcode]
      is_optional? && fields.none?(&:present?)
    end
  end
end
