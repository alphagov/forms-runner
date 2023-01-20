module Question
  class Name < Question::QuestionBase
    attribute :title
    attribute :full_name
    attribute :first_name
    attribute :middle_name
    attribute :last_name

    validate :full_name_valid?, if: :is_full_name?
    validate :first_and_last_name_valid?, unless: :is_full_name?

    def validate_title
      needs_title? && !is_optional?
    end

    def needs_title?
      answer_settings.present? && answer_settings&.title_needed
    end

    def is_full_name?
      answer_settings.present? && answer_settings&.input_type == "full_name"
    end

    def include_middle_name?
      answer_settings.present? && answer_settings&.input_type == "first_middle_and_last_name"
    end

    def skipping_question?
      fields = [title, full_name, first_name, middle_name, last_name]
      is_optional? && fields.none?(&:present?)
    end

    def full_name_valid?
      return if skipping_question?

      errors.add(:title, :blank) if needs_title? && title.blank?
      errors.add(:full_name, :blank) if full_name.blank?
      errors
    end

    def first_and_last_name_valid?
      return if skipping_question?

      errors.add(:title, :blank) if needs_title? && title.blank?
      errors.add(:first_name, :blank) if first_name.blank?
      errors.add(:last_name, :blank) if last_name.blank?
      errors
    end

    def show_answer
      # TODO: Make sure the names display sensibly on the CYA page / the notify email
    end
  end
end
