module Question
  class QuestionBase
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Serialization
    include ActiveModel::Attributes

    attr_accessor :question_text, :question_short_name, :hint_text

    def initialize(attributes = {}, options = {})
      super(attributes)
      @question_text = options[:question_text]
      @question_short_name = options[:question_short_name]
      @hint_text = options[:hint_text]
    end

    def attributes
      attribute_names.index_with { |_k| nil }
    end

    def show_answer
      attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(", ")
    end
  end
end
