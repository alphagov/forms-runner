module Flow
  class FormContext
    ANSWERS_KEY = :answers

    def initialize(store)
      @store = store
      @store[ANSWERS_KEY] ||= {}
    end

    def save_step(step, answer)
      @store[ANSWERS_KEY][form_key(step)] ||= {}
      @store[ANSWERS_KEY][form_key(step)][page_key(step)] = answer
    end

    def get_stored_answer(step)
      @store.dig(ANSWERS_KEY, form_key(step), page_key(step))
    end

    def clear_stored_answer(step)
      @store.dig(ANSWERS_KEY, form_key(step))&.delete(page_key(step))
    end

    def clear(form_id)
      @store[ANSWERS_KEY][form_id.to_s] = nil
    end

    def form_submitted?(form_id)
      @store[ANSWERS_KEY][form_id.to_s].nil?
    end

  private

    def page_key(step)
      step.page_id.to_s
    end

    def form_key(step)
      step.form_id.to_s
    end
  end
end
