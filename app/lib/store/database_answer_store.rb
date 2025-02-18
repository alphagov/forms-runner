module Store
  class DatabaseAnswerStore
    include Store::Access

    def initialize(answers)
      @answers = answers
    end

    def get_stored_answer(step)
      @answers[page_key(step)]
    end
  end
end
