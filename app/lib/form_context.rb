class FormContext
  ROOT_KEY = :answers
  def initialize(store)
    @store = store
    @store[ROOT_KEY] ||= {}
  end

  def save_step(step, answer)
    @store[ROOT_KEY][form_key(step)] ||= {}
    @store[ROOT_KEY][form_key(step)][page_key(step)] = answer
  end

  def get_stored_answer(step)
    @store.dig(ROOT_KEY, form_key(step), page_key(step))
  end

  def clear_stored_answer(step)
    @store.dig(ROOT_KEY, form_key(step))&.delete(page_key(step))
  end

  def clear(form_id)
    @store[ROOT_KEY][form_id.to_s] = nil
  end

private

  def page_key(step)
    step.page_id.to_s
  end

  def form_key(step)
    step.form_id.to_s
  end
end
