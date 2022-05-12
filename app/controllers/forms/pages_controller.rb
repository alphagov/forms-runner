module Forms
  class PagesController < ApplicationController
    before_action :prepare_form, :page_params

    def show; end

    def create
      @page = Page.new(page_params)

      if @page.valid? && submit
        redirect_to :submitted_form_page
      else
        render :show
      end
    end

    def submitted; end

    private

    def page_params
      { text: params[:text] }
    end

    def allow_params
      params.permit(:text, :form_id)
    end

    def prepare_form
      @form = Form.find(params[:form_id])
    end

    def submit
      # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
      NotifyService.new.send_email(@form.submission_email, @form.name, @page.text, Time.now)
      Rails.logger.info "Form submitted #{@page.serializable_hash}"
      # forms always submit corectly, to add error handling
      true
    end
  end
end
