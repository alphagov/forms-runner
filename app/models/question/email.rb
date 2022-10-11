module Question
  class Email < Question::QuestionBase
    # see https://design-system.service.gov.uk/patterns/email-addresses/
    # This model contains very lite checking - only that an @ exists. Pay and
    # notify both have good examples of better email validation checks and ways
    # to help users enter the right value

    EMAIL_REGEX = /.*@.*/
    attribute :email
    validates :email, presence: true, unless: :is_optional?
    validates :email, format: { with: EMAIL_REGEX, message: :invalid_email }, allow_blank: true
  end
end
