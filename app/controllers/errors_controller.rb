class ErrorsController < ApplicationController
  skip_before_action :check_maintenance_mode_is_enabled, only: :maintenance

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Resource not found" }, status: :not_found }
      format.all { render status: :not_found, body: nil }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  def maintenance
    render "errors/maintenance", formats: :html
  end

  def deprecated
    form = Form.find params.require(:form_id)
    page = Page.find params.require(:page_id), params: { form_id: params.require(:form_id) }
    redirect_to form_page_path(form_id: form.id, form_slug: form.form_slug, page_slug: page.id, mode: :form)
  end

  def new_timeout; end

  def timeout
    sleep 45 # CloudFront timeout is 30 seconds (default)
    render "errors/submission_error"
  end
end
