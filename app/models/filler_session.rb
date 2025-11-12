class FillerSession
  attr_reader :form_id, :mode

  def initialize(session, form_id:, mode:)
    @session = session
    @form_id = form_id
    @mode = mode
  end

  def form_document
    @form_document ||= form.document_json
  end

  def form
    @form ||= load_form
  end

  def context
    @context ||= Flow::Context.new(form: form, store: @session)
  end

private

  def load_form
    get_stored_form || save_form(find_form)
  end

  def get_stored_form
    form_document = form_document_store.get_stored
    return nil if form_document.blank?

    Form.from_form_document(form_id, mode.tag, form_document)
  end

  def save_form(form)
    form_document_store.save(form.document_json)
    form
  end

  def find_form
    Api::V2::FormRepository.find_with_mode(form_id:, mode:)
  end

  def form_document_store
    @form_document_store ||= Store::SessionFormDocumentStore.new(
      @session, form_id, mode.tag,
    )
  end
end
