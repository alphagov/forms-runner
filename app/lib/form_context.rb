class FormContext
  ROOT_KEY = :answers
  def initialize(store, form)
    @store = store
    @store[ROOT_KEY] ||= {}

    @form_key = form.id.to_s
    @store[ROOT_KEY][@form_key] ||= {}

    @form_store = @store[ROOT_KEY][@form_key]
  end

  def store_answer(page, answer)
    @form_store[page_key(page)] = answer
  end

  def get_stored_answer(page)
    @form_store[page_key(page)]
  end

  def clear_answers
    @store[ROOT_KEY][@form_key] = nil
  end

  def answers
    @form_store || {}
  end

private

  def page_key(page)
    page.id.to_s
  end
end
