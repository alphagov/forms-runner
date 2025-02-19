module Flow
  class Context
    attr_reader :form, :support_details, :journey

    def initialize(form:, store:)
      @form = form
      @answer_store = Store::SessionAnswerStore.new(store, form.id)
      @confirmation_details_store = Store::ConfirmationDetailsStore.new(store)
      @journey = Journey.new(answer_store: @answer_store, form:)

      @support_details = OpenStruct.new({
        email: form.support_email,
        phone: form.support_phone,
        call_charges_url: "https://www.gov.uk/call-charges",
        url: form.support_url,
        url_text: form.support_url_text,
      })
    end

    delegate :find_or_create, :previous_step, :next_page_slug, :next_step, :can_visit?, :completed_steps, :all_steps, to: :journey
    delegate :clear_stored_answer, :clear, :form_submitted?, to: :answer_store

    def save_step(step)
      return false unless step.valid?

      step.save_to_store(@answer_store)
    end

    def save_submission_details(reference, requested_email_confirmation)
      @confirmation_details_store.save_submission_details(form.id, reference, requested_email_confirmation)
    end

    def get_submission_reference
      @confirmation_details_store.get_submission_reference(form.id)
    end

    def requested_email_confirmation?
      @confirmation_details_store.requested_email_confirmation?(form.id)
    end

    def clear_submission_details
      @confirmation_details_store.clear_submission_details(form.id)
    end

  private

    attr_reader :answer_store
  end
end
