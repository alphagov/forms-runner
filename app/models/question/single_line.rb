class Question::SingleLine < Question::QuestionBase
  attribute :text
  validates :text, presence: true
end
