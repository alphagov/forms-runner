class Question::SingleLine < Question::ApplicationQuestion
  attribute :text
  validates :text, presence: true
end
