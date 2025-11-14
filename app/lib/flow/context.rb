module Flow
  class Context
    attr_reader :form, :journey, :locale

    def initialize(form:, store:, locale: :en)
      @form = form
      @answer_store = Store::SessionAnswerStore.new(store, form.id)
      @confirmation_details_store = Store::ConfirmationDetailsStore.new(store, form.id)
      @journey = Journey.new(answer_store: @answer_store, form:)
      @locale = locale
    end

    delegate :support_details, to: :form
    delegate :find_or_create, :previous_step, :next_page_slug, :next_step, :can_visit?, :completed_steps, :all_steps, to: :journey
    delegate :clear_stored_answer, :clear, :form_submitted?, :answers, to: :answer_store
    delegate :save_submission_details, :get_submission_reference, :requested_email_confirmation?, :clear_submission_details, to: :confirmation_details_store

    def save_step(step)
      return false unless step.valid?

      step.save_to_store(@answer_store)
    end

  private

    attr_reader :answer_store, :confirmation_details_store
  end
end
