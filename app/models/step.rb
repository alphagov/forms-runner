class Step
  attr_accessor :page_id, :form_id, :question
  attr_reader :next_page_slug, :page_slug

  def initialize(question:, page_id:, form_id:, next_page_slug:, is_start_page:, page_slug:)
    @question = question
    @page_id = page_id
    @page_slug = page_slug
    @form_id = form_id

    @is_start_page = is_start_page
    @next_page_slug = next_page_slug
  end

  def id
    @page_id
  end

  def ==(other)
    @page_id == other.page_id
  end

  def save_to_context(form_context)
    form_context.save_step(self, @question.serializable_hash)
    self
  end

  def load_from_context(form_context)
    attrs = form_context.get_stored_answer(self)
    @question.assign_attributes(attrs || {})
    self
  end

  def update!(params)
    @question.assign_attributes(params)
    @question.valid?
  end

  def params
    @question.attribute_names
  end

  def valid?
    @question.valid?
  end

  def clear_errors
    @question.errors.clear
  end

  def show_answer
    @question.show_answer
  end

  def question_text
    @question.question_text
  end

  def hint_text
    @question.hint_text
  end

  def question_short_name
    @question.question_short_name
  end

  def end_page?
    next_page_slug.nil?
  end

  def start_page?
    @is_start_page
  end
end
