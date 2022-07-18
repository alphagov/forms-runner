class Question::SingleLine < Question::QuestionBase
  attribute :text
  validates :text, presence: true
  validates :text, length: { maximum: 499 }
end
