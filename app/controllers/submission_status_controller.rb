class SubmissionStatusController < ApplicationController
  before_action :authenticate_client
  def status
    if Submission.emailed?(submission_params[:reference])
      head :no_content
    else
      head :not_found
    end
  end

private

  def authenticate_client
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Settings.submission_status_api[:secret])
    end
  end

  def submission_params
    params.permit(:reference)
  end
end
