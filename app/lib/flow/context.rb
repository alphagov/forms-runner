module Flow
  class Context
    attr_reader :form, :support_details

    def initialize(form:, store:)
      @form = form
      @form_context = Flow::FormContext.new(store)
      @confirmation_details_store = Store::ConfirmationDetailsStore.new(store)
      @journey = Journey.new(form_context: @form_context, form:)

      @support_details = OpenStruct.new({
        email: form.support_email,
        phone: form.support_phone,
        call_charges_url: "https://www.gov.uk/call-charges",
        url: form.support_url,
        url_text: form.support_url_text,
      })
    end

    def find_or_create(page_slug)
      @journey.find_or_create(page_slug)
    end

    def save_step(step)
      return false unless step.valid?

      step.save_to_context(@form_context)
    end

    def clear_stored_answer(step)
      @form_context.clear_stored_answer(step)
    end

    def previous_step(page_slug)
      @journey.previous_step(page_slug)
    end

    def next_page_slug
      @journey.next_page_slug
    end

    def next_step
      @journey.next_step
    end

    def can_visit?(page_slug)
      @journey.can_visit?(page_slug)
    end

    def completed_steps
      @journey.completed_steps
    end

    def all_steps
      @journey.all_steps
    end

    def clear
      @form_context.clear(form.id)
    end

    def form_submitted?
      @form_context.form_submitted?(form.id)
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
  end
end
