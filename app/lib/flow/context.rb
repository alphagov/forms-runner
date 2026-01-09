module Flow
  class Context
    attr_reader :form, :journey

    def initialize(form:, store:)
      @form = form
      @answer_store = Store::SessionAnswerStore.new(store, form.id)
      @confirmation_details_store = Store::ConfirmationDetailsStore.new(store, form.id)
      @journey = Journey.new(answer_store: @answer_store, form:)
    end

    delegate :support_details, to: :form
    delegate :find_or_create, :previous_step, :next_page_slug, :next_step, :can_visit?, :completed_steps, :all_steps, to: :journey
    delegate :clear_stored_answer, :clear, :form_submitted?, :answers, to: :answer_store
    delegate :save_submission_details, :get_submission_reference, :requested_email_confirmation?, :clear_submission_details, to: :confirmation_details_store

    def save_step(step, context: nil)
      is_valid = step.valid?(context)

      unless is_valid
        record_validation_failure(step)
      end

      return false unless is_valid

      step.save_to_store(@answer_store)
    end

    def record_validation_failure(step)
      return unless defined?(OpenTelemetry)

      span = OpenTelemetry::Trace.current_span

      span.add_event("validation_failed", attributes: {
        "question.type" => step.question.class.name,
        "question.id" => step.page_id,
        "question.text" => step.question_text,
        "question.answer_type" => step.page&.answer_type,
        "validation.errors" => step.question.errors.full_messages.join(", "),
        "validation.error_count" => step.question.errors.count,
        "validation.error_attributes" => step.question.errors.attribute_names.map(&:to_s).join(", "),
      })

      span.set_attribute("validation.failed", true)
      span.set_attribute("validation.error_count", step.question.errors.count)
    end

  private

    attr_reader :answer_store, :confirmation_details_store
  end
end
