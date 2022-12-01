module Question
  class Selection < QuestionBase
    attribute :selection
    validates :selection, presence: true
    validate :selection, :validate_checkbox, if: :allow_multiple_answers?

    def allow_multiple_answers?
      answer_settings.allow_multiple_answers == "true"
    end

    def show_answer
      if allow_multiple_answers?
        selection_without_blanks&.join(", ")
      else
        selection
      end
    end

  private

    def selection_without_blanks
      selection.reject(&:blank?)
    end

    def validate_checkbox
      return errors.add(:selection, :blank) if selection_without_blanks.empty?
      return errors.add(:selection, :both_none_and_value_selected) if selection_without_blanks.count > 1 && "None of the above".in?(selection_without_blanks)
    end
  end
end
