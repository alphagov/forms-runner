class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
    end
  end

  def check_your_answers
    @form = Form.find(params.require(:form_id))
    @answers = session[:answers][@form.id.to_s]
    last_page = @form.pages.find { |p| !p.has_next? }
    @back_link = form_page_path(@form.id, last_page.id)
    @rows = check_your_answers_rows(@form, @answers)
  end

  def submit_answers
    @form = Form.find(params.require(:form_id))
    # Comment out submission until we are ready to use notify to send answers
    # answers = session[:answers]
    # submit(answers)
    clear_answers(:form_id)
    redirect_to :form_submitted
  end

  def submitted
    @form = Form.find(params.require(:form_id))
  end

private

  def submit(answers)
    # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
    NotifyService.new.send_email(@form.submission_email, @form.name, answers, Time.zone.now)
    # forms always submit corectly, to add error handling
    true
  end

  def clear_answers(form_id)
    session[:answers][form_id] = nil
  end

  def check_your_answers_rows(form, answers = {})
    logger.info "answers: #{answers}"
    answers&.to_a&.sort_by(&:first)&.map do |page_id, answer|
      page = form.pages.find { |p| p.id == page_id.to_i }
      logger.info "p = #{page_id}"
      {
        key: { text: page.question_text },
        value: { text: page.question.new(answer).value },
        actions: [{ href: form_page_url(form, page), visually_hidden_text: "" }],
      }
    end
  end
end
