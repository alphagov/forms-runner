module Store
  class SessionFormDocumentStore

    FORMS_KEY = :forms

    def initialize(store, form_id, tag)
      @store = store
      @form_key = form_id.to_s
      @tag_key = tag.to_s
      @store[FORMS_KEY] ||= {}
    end

    def save(form_document)
      @store[FORMS_KEY][@form_key] ||= {}
      @store[FORMS_KEY][@form_key][@tag_key] = form_document
    end

    def get_stored
      @store.dig(FORMS_KEY, @form_key, @tag_key)
    end

    def clear
      @store.dig(FORMS_KEY, @form_key)&.delete(@tag_key)
    end
  end
end
