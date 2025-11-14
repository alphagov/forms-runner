module Store
  class SessionAnswerStore
    include Store::Access

    ANSWERS_KEY = :answers

    def initialize(store, form_id)
      @store = store
      @form_key = form_id.to_s
      @store[ANSWERS_KEY] ||= {}
    end

    def save_step(step, answer)
      @store[ANSWERS_KEY][@form_key] ||= {}
      @store[ANSWERS_KEY][@form_key][page_key(step)] = answer
    end

    def get_stored_answer(step)
      return nil if answers.nil?

      if answers.key?(page_key(step))
        answers[page_key(step)]
      elsif step.database_id && answers.key?(step.database_id)
        answers[step.database_id]
      end
    end

    def clear_stored_answer(step)
      return nil if answers.nil?

      answers.delete(page_key(step)) if answers.key?(page_key(step))
      answers.delete(step.database_id) if step.database_id && answers.key?(step.database_id)
    end

    def clear
      @store[ANSWERS_KEY][@form_key] = nil
    end

    def form_submitted?
      @store[ANSWERS_KEY][@form_key].nil?
    end

    def answers
      @store[ANSWERS_KEY][@form_key]
    end
  end
end
