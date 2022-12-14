module Question
  class OrganisationName < QuestionBase
    attribute :text
    validates :text, presence: true, unless: :is_optional?
    validates :text, length: { maximum: 499 }
  end
end
