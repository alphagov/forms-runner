module Question
  class QuestionBase
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Serialization
    include ActiveModel::Attributes
    include ActionView::Helpers::TagHelper

    attr_accessor :question_text, :hint_text, :answer_settings, :is_optional, :page_heading, :guidance_markdown

    after_validation :set_validation_error_logging_attributes

    def initialize(attributes = {}, options = {})
      super(attributes)
      @question_text = options[:question_text]
      @hint_text = options[:hint_text]
      @is_optional = options[:is_optional]
      @answer_settings = options[:answer_settings]
      @page_heading = options[:page_heading]
      @guidance_markdown = options[:guidance_markdown]
    end

    def before_save
      # only implemented for questions where we need to perform an action before saving the answer to the session
    end

    def attributes
      attribute_names.index_with { |_k| nil }
    end

    def answered?
      @attributes.to_hash.any? { |_key, value| !value.nil? }
    end

    def show_answer
      attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(", ")
    end

    def show_answer_in_email
      show_answer
    end

    def show_answer_in_csv(*)
      Hash[question_text, show_answer]
    end

    def is_optional?
      @is_optional == true
    end

    def has_long_answer?
      false
    end

    def show_optional_suffix
      is_optional?
    end

    def question_text_with_optional_suffix
      return question_text unless show_optional_suffix

      "#{question_text} #{I18n.t('page.optional')}"
    end

    def question_text_for_check_your_answers
      question_text_with_optional_suffix
    end

  private

    def set_validation_error_logging_attributes
      CurrentRequestLoggingAttributes.validation_errors = errors.map { |error| "#{error.attribute}: #{error.type}" } if errors.any?
    end
  end
end
