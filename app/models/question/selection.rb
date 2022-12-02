module Question
  class Selection < QuestionBase
    attribute :selection
    validates :selection, presence: true
    validate :selection, :validate_checkbox, if: :allow_multiple_answers?
    validate :selection, :validate_radio, unless: :allow_multiple_answers?

    def allow_multiple_answers?
      answer_settings.allow_multiple_answers == "true"
    end

    def show_answer
      answer = if allow_multiple_answers?
                 selection_without_blanks.join(", ")
               else
                 selection
               end
      replace_none_of_the_above(answer)
    end

  private

    def replace_none_of_the_above(answer)
      if answer == :none_of_the_above.to_s
        I18n.t("page.none_of_the_above")
      else
        answer
      end
    end

    def allowed_options
      options = answer_settings.selection_options.map(&:name).map(&:to_sym)
      if is_optional?
        options.concat([:none_of_the_above])
      end
      options
    end

    def selection_without_blanks
      selection.reject(&:blank?)
    end

    def validate_radio
      return errors.add(:selection, :inclusion) if allowed_options.exclude?(selection.to_sym)
    end

    def validate_checkbox
      return errors.add(:selection, :blank) if selection_without_blanks.empty?
      return errors.add(:selection, :both_none_and_value_selected) if selection_without_blanks.count > 1 && :none_of_the_above.to_s.in?(selection_without_blanks)
      return errors.add(:selection, :inclusion) if selection_without_blanks.any? { |item| allowed_options.exclude?(item.to_sym) }
    end
  end
end
