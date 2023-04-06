module Question
  class QuestionBase
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Serialization
    include ActiveModel::Attributes

    attr_accessor :question_text, :hint_text, :answer_settings

    def initialize(attributes = {}, options = {})
      super(attributes)
      @question_text = options[:question_text]
      @hint_text = options[:hint_text]
      @is_optional = options[:is_optional]
      @answer_settings = options[:answer_settings]
    end

    def attributes
      attribute_names.index_with { |_k| nil }
    end

    def show_answer
      attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(", ")
    end

    def show_answer_in_email
      show_answer
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
  end
end
