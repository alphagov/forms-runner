module Question
  class LongText < QuestionBase
    attribute :text
    validates :text, presence: true, unless: :is_optional?
    validates :text, length: { maximum: 5000 }

    def has_long_answer?
      true
    end
  end
end
