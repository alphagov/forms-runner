module Store
  class ConfirmationDetailsStore
    CONFIRMATION_KEY = :confirmation_details
    SUBMISSION_REFERENCE_KEY = :submission_reference
    REQUESTED_EMAIL_KEY = :requested_email_confirmation

    def initialize(store, form_id)
      @store = store
      @form_key = form_id.to_s
      @store[CONFIRMATION_KEY] ||= {}
    end

    def save_submission_details(reference, requested_email_confirmation)
      @store[CONFIRMATION_KEY][@form_key] ||= {}
      @store[CONFIRMATION_KEY][@form_key][SUBMISSION_REFERENCE_KEY.to_s] = reference
      @store[CONFIRMATION_KEY][@form_key][REQUESTED_EMAIL_KEY.to_s] = requested_email_confirmation
    end

    def get_submission_reference
      @store.dig(CONFIRMATION_KEY, @form_key, SUBMISSION_REFERENCE_KEY.to_s)
    end

    def requested_email_confirmation?
      @store.dig(CONFIRMATION_KEY, @form_key, REQUESTED_EMAIL_KEY.to_s)
    end

    def clear_submission_details
      @store[CONFIRMATION_KEY][@form_key] = nil
    end
  end
end
