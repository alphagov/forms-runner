module Store
  class ConfirmationDetailsStore
    CONFIRMATION_KEY = :confirmation_details
    SUBMISSION_REFERENCE_KEY = :submission_reference
    REQUESTED_EMAIL_KEY = :requested_email_confirmation

    def initialize(store)
      @store = store
      @store[CONFIRMATION_KEY] ||= {}
    end

    def save_submission_details(form_id, reference, requested_email_confirmation)
      @store[CONFIRMATION_KEY][form_id.to_s] ||= {}
      @store[CONFIRMATION_KEY][form_id.to_s][SUBMISSION_REFERENCE_KEY.to_s] = reference
      @store[CONFIRMATION_KEY][form_id.to_s][REQUESTED_EMAIL_KEY.to_s] = requested_email_confirmation
    end

    def get_submission_reference(form_id)
      @store.dig(CONFIRMATION_KEY, form_id.to_s, SUBMISSION_REFERENCE_KEY.to_s)
    end

    def requested_email_confirmation?(form_id)
      @store.dig(CONFIRMATION_KEY, form_id.to_s, REQUESTED_EMAIL_KEY.to_s)
    end

    def clear_submission_details(form_id)
      @store[CONFIRMATION_KEY][form_id.to_s] = nil
    end
  end
end
