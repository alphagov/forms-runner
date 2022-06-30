class Question::PhoneNumber < Question::QuestionBase
  attribute :phone_number
  validates :phone_number, presence: true
end
