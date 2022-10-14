module Question
  class Number < QuestionBase
    attribute :number
    validates :number, presence: true
    validates :number, numericality: { greater_than_or_equal_to: 0 }
  end
end
