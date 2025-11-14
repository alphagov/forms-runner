module Question
  class Selection < QuestionBase
    attribute :selection
    attribute :none_of_the_above_answer

    before_validation :clear_none_of_the_above_answer_if_not_selected

    validates :selection, presence: true
    validate :selection, :validate_checkbox, if: :allow_multiple_answers?
    validate :selection, :validate_radio, unless: :allow_multiple_answers?
    validates :none_of_the_above_answer, length: { maximum: 499 }

    with_options unless: :autocomplete_component? do
      validates :none_of_the_above_answer, presence: true, if: :validate_none_of_the_above_answer_presence?
    end

    def allow_multiple_answers?
      answer_settings.only_one_option != "true"
    end

    def show_answer
      return selection_without_blanks.map { |selected| name_from_value(selected) }.join(", ") if allow_multiple_answers?

      selection_name
    end

    def show_answer_in_email
      return selection_without_blanks.join("\n\n") if allow_multiple_answers?

      selection
    end

    def show_answer_in_json(*)
      hash = {}

      hash[:selections] = selection_without_blanks if allow_multiple_answers?
      hash[:answer_text] = show_answer

      hash
    end

    def selection_name
      return nil if selection.nil?
      return "" if selection.blank?

      name_from_value(selection)
    end

    # Show the selection option name, which can be different to the value. Value
    # should stay the same across FormDocuments in different languages.
    def name_from_value(selected)
      @options_by_value ||= answer_settings.selection_options.index_by(&:value)
      @options_by_value[selected]&.name
    end

    def show_optional_suffix
      false
    end

    def selection_options_with_none_of_the_above
      options = answer_settings.selection_options

      return options unless is_optional?

      [*options, none_of_the_above_option]
    end

    def autocomplete_component?
      answer_settings.selection_options.count > 30
    end

    def has_none_of_the_above_question?
      none_of_the_above_question.present?
    end

  private

    def clear_none_of_the_above_answer_if_not_selected
      self.none_of_the_above_answer = nil unless none_of_the_above_selected?
    end

    def allowed_options
      selection_options_with_none_of_the_above.map(&:value)
    end

    def none_of_the_above_option
      OpenStruct.new(name: I18n.t("page.none_of_the_above"), value: I18n.t("page.none_of_the_above"))
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

    def validate_none_of_the_above_answer_presence?
      none_of_the_above_question.present? && none_of_the_above_question.is_optional != "true" && none_of_the_above_selected?
    end

    def none_of_the_above_question
      return nil unless is_optional?
      return nil unless answer_settings.respond_to?(:none_of_the_above_question)
      return nil unless answer_settings.none_of_the_above_question.respond_to?(:question_text)

      answer_settings.none_of_the_above_question
    end

    def none_of_the_above_selected?
      return selection_without_blanks.include?(I18n.t("page.none_of_the_above")) if allow_multiple_answers?

      selection == I18n.t("page.none_of_the_above")
    end
  end
end
