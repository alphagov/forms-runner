class FormController < Forms::FormController
  rescue_from ActiveResource::ResourceNotFound do
    render template: "errors/not_found", status: :not_found
  end

  def show
    @form = Form.find(params.require(:form_id))
    if @form.start_page
      redirect_to form_page_path(params.require(:form_id), @form.start_page)
      unless preview?
        EventLogger.log_form_event(Context.new(form: @form, store: session), request, "visit")
      end
    end
  end

  def submitted
    @form = Form.find(params.require(:form_id))
  end
end
