class Question::PhoneNumber < Question::ApplicationQuestion
  attribute :phone_number
  validates :phone_number, presence: true
end
