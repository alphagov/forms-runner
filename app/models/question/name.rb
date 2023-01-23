module Question
  class Name < Question::QuestionBase
    attribute :title
    attribute :full_name
    attribute :first_name
    attribute :middle_names
    attribute :last_name

    validate :full_name_valid?, if: :is_full_name?
    validate :first_and_last_name_valid?, unless: :is_full_name?

    def validate_title
      needs_title? && !is_optional?
    end

    def needs_title?
      answer_settings.present? && answer_settings&.title_needed == "true"
    end

    def is_full_name?
      answer_settings.present? && answer_settings&.input_type == "full_name"
    end

    def include_middle_name?
      answer_settings.present? && answer_settings&.input_type == "first_middle_and_last_name"
    end

    def skipping_question?
      fields = [title, full_name, first_name, middle_names, last_name]
      is_optional? && fields.none?(&:present?)
    end

    def full_name_valid?
      return if skipping_question?

      errors.add(:full_name, :blank) if full_name.blank?
      errors
    end

    def first_and_last_name_valid?
      return if skipping_question?

      errors.add(:first_name, :blank) if first_name.blank?
      errors.add(:last_name, :blank) if last_name.blank?
      errors
    end

    def show_answer
      attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(" ")
    end

    def show_answer_in_email
      attribute_names.reject { |attribute| has_blank_values?(attribute) }.map { |attribute| generate_string_for_processing_email(attribute) }&.join("\n\n")
    end

    def has_blank_values?(attribute)
      send(attribute).blank?
    end

    def generate_string_for_processing_email(attribute)
      "#{friendly_name_for_attribute(attribute)}: #{send(attribute)}"
    end

    def friendly_name_for_attribute(attribute)
      I18n.t("question/name.label.#{attribute}")
    end
  end
end
