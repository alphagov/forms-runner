module Forms
  class FormController < ApplicationController
    def current_context
      @current_context ||= Context.new(form: Form.find(params.require(:form_id)), store: session)
    end
  end
end
