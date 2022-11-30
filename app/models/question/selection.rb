module Question
  class Selection < QuestionBase
    attribute :selection

    def allow_multiple_answers
      answer_settings.allow_multiple_answers == "true"
    end

    def show_answer
      if allow_multiple_answers
        attribute_names.map { |attribute| send(attribute) }.first.reject(&:blank?)&.join(", ")
      else
        attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(", ")
      end
    end
  end
end
