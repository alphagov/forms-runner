class Question::Email < Question::ApplicationQuestion
  attribute :email
  validates :email, presence: true
end
