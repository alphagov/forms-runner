module Question
    class LongText < QuestionBase
      attribute :text
      validates :text, presence: true
      validates :text, length: { maximum: 5000 }
    end
  end
  