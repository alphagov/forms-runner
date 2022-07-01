module Question
  class QuestionBase
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Serialization
    include ActiveModel::Attributes

    attr_accessor :question_text, :question_short_name, :hint_text

    def attributes
      attribute_names.index_with { |_k| nil }
    end

    def show_answer
      attribute_names.map { |attribute| send(attribute) }.reject(&:blank?)&.join(", ")
    end
  end
end
