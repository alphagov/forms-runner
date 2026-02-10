module Question
  class GetACopyOfYourAnswers < Question::QuestionBase
    attribute :get_a_copy_of_your_answers

    validates :get_a_copy_of_your_answers, presence: true
    validates :get_a_copy_of_your_answers, inclusion: { in: %w[yes no] }

    def show_answer
      get_a_copy_of_your_answers.humanize
    end

    def question_text_for_check_your_answers
      "Get a copy of your answers"
    end
  end
end
