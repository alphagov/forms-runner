class FormController < ApplicationController
  before_action :prepare_form, except: [:show]

  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
      log_form_event(@form, request, "visit")
    end
  end

  def check_your_answers
    form_context = FormContext.new(session, @form)
    @answers = form_context.answers
    @back_link = form_page_path(@form, @form.last_page)
    @rows = check_your_answers_rows(@form, @answers)
    log_form_event(@form, request, "check_answers")
  end

  def submit_answers
    form_context = FormContext.new(session, @form)
    answers = form_context.answers
    submit_form(formatted_answers(@form, answers))
    form_context.clear_answers
    log_form_event(@form, request, "submission")
    redirect_to :form_submitted
  rescue StandardError
    render "errors/submission_error", status: :internal_server_error
  end

  def submitted; end

private

  def prepare_form
    @form = Form.find(params.require(:form_id))
  end

  def submit_form(text)
    # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
    NotifyService.new.send_email(@form.submission_email, @form.name, text, Time.zone.now)
  end

  def check_your_answers_rows(form, answers = {})
    form.pages.map do |page|
      answer = answers[page.id.to_s]
      question_name = page.question_short_name.presence || page.question_text
      question = QuestionRegister.from_page(page).new(answer)
      {
        key: { text: question_name },
        value: { text: question.show_answer },
        actions: [{ href: form_change_answer_path(form, page), visually_hidden_text: question_name }],
      }
    end
  end

  def formatted_answers(form, answers = {})
    form.pages.map { |page|
      answer = answers[page.id.to_s]
      question = QuestionRegister.from_page(page).new(answer)
      "#{page.question_text}: #{question.show_answer}"
    }.join("\n")
  end

  def log_form_event(form, request, event)
    item_to_log = {
      url: request&.url,
      method: request&.method,
      form: form&.name,
      user_agent: request&.user_agent,
    }

    EventLogger.log("form_#{event}", item_to_log)
  end
end
