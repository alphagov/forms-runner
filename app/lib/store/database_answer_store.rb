module Store
  class DatabaseAnswerStore
    include Store::Access

    def initialize(answers)
      @answers = answers
    end

    def get_stored_answer(step)
      if @answers.key?(page_key(step))
        @answers[page_key(step)]
      elsif step.database_id && @answers.key?(step.database_id)
        @answers[step.database_id]
      end
    end
  end
end
