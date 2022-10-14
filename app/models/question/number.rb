module Question
  class Number < QuestionBase
    attribute :number
    validates :number, presence: true, unless: :is_optional?
    validates :number, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  end
end
