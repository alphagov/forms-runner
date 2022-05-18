module Forms
  class PagesController < ApplicationController
    before_action :prepare_form

    def new
      @page = Page.new
    end

    def create
      @page = Page.new(page_params)

      if @page.valid? && submit
        # could be if submit successful
        redirect_to :submitted_form_page
        # if unsuccessful redirect to an error
      else
        render :new
      end
    end

    def submitted; end

  private

    def page_params
      params.require(:page).permit(:text)
    end

    def prepare_form
      @form = Form.find(params.require(:form_id))
    end

    def submit
      # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
      NotifyService.new.send_email(@form.submission_email, @form.name, @page.text, Time.zone.now)
      Rails.logger.info "Form submitted #{@page.serializable_hash}"
      # forms always submit corectly, to add error handling
      true
    end
  end
end
