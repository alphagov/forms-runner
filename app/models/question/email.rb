module Question
  class Email < Question::QuestionBase
    attribute :email
    validates :email, presence: true, unless: :is_optional?
    validates :email, email_address: { message: :invalid_email }, allow_blank: true
  end
end
