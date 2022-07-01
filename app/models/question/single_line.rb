module Question
  class SingleLine < QuestionBase
    attribute :text
    validates :text, presence: true
    validates :text, length: { maximum: 499 }
  end
end
