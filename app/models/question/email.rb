class Question::Email < Question::QuestionBase
  attribute :email
  validates :email, presence: true
end
