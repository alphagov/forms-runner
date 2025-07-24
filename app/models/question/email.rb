module Question
  class Email < Question::QuestionBase
    before_validation :strip_whitespace

    attribute :email
    validates :email, presence: true, unless: :is_optional?
    validates :email, email_address: { message: :invalid_email }, allow_blank: true

    def strip_whitespace
      if email.present?
        self.email = NotificationsUtils::Formatters.strip_and_remove_obscure_whitespace(email)
      end
    end
  end
end
