module Store
  class DatabaseAnswerStore
    include Store::Access

    def initialize(answers)
      @answers = answers
    end

    def get_stored_answer(step)
      if @answers.key?(page_key(step))
        @answers[page_key(step)]
      elsif database_id_key(step) && @answers.key?(database_id_key(step))
        @answers[database_id_key(step)]
      end
    end
  end
end
