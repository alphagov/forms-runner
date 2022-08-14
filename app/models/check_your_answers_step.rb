class CheckYourAnswersStep
  attr_reader :next_page_slug, :page_slug, :page_id, :form_id

  def initialize(form_id:)
    @form_id = form_id
    @page_id = "check_your_answers"
    @next_page_slug = "_submit" # not used for now
    @page_slug = "check_your_answers"
  end

  def ==(other)
    other.class == self.class && other.state == state
  end

  def state
    instance_variables.map { |variable| instance_variable_get variable }
  end

  def end_page?
    true
  end
end
