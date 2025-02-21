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
      @store.dig(ANSWERS_KEY, @form_key, page_key(step))
    end

    def clear_stored_answer(step)
      @store.dig(ANSWERS_KEY, @form_key)&.delete(page_key(step))
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
