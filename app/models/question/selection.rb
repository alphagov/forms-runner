module Question
  class Selection < QuestionBase
    attribute :selection
    validates :selection, presence: true
    validate :selection, :validate_checkbox, if: :allow_multiple_answers?
    validate :selection, :validate_radio, unless: :allow_multiple_answers?

    def allow_multiple_answers?
      answer_settings.only_one_option != "true"
    end

    def show_answer
      return selection_without_blanks.join(", ") if allow_multiple_answers?

      selection
    end

    def show_answer_in_email
      return selection_without_blanks.join("\n\n") if allow_multiple_answers?

      selection
    end

    def show_optional_suffix
      false
    end

    def selection_options_with_none_of_the_above
      options = answer_settings.selection_options

      return options unless is_optional?

      [*options, none_of_the_above_option]
    end

  private

    def allowed_options
      selection_options_with_none_of_the_above.map(&:name)
    end

    def none_of_the_above_option
      OpenStruct.new(name: I18n.t("page.none_of_the_above"))
    end

    def selection_without_blanks
      return [] if selection.nil?

      selection.reject(&:blank?)
    end

    def validate_radio
      errors.add(:selection, :inclusion) if allowed_options.exclude?(selection)
    end

    def validate_checkbox
      return errors.add(:selection, is_optional? ? :both_none_and_value_selected : :checkbox_blank) if selection_without_blanks.empty?
      return errors.add(:selection, :both_none_and_value_selected) if selection_without_blanks.count > 1 && I18n.t("page.none_of_the_above").in?(selection_without_blanks)

      errors.add(:selection, :inclusion) if selection_without_blanks.any? { |item| allowed_options.exclude?(item) }
    end
  end
end
