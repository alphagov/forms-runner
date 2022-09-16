module Forms
  class FormController < ApplicationController
    def current_context
      @current_context ||= Context.new(form: Form.find(params.require(:form_id)), store: session)
    end

  private

    def preview?
      params[:mode] == "preview-form"
    end

    def mode
      params[:mode]
    end

    def default_url_options
      { mode: }
    end
  end
end
