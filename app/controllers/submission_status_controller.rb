class SubmissionStatusController < ApplicationController
  def status
    if Submission.emailed?(submission_params[:reference])
      head :no_content
    else
      head :not_found
    end
  end

private

  def submission_params
    params.permit(:reference)
  end
end
