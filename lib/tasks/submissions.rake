namespace :submissions do
  desc "Update mode for submission"
  task :update_mode, %i[submission_reference mode] => :environment do |_, args|
    submission_reference = args[:submission_reference]
    mode = args[:mode]

    usage_message = "usage: rake submissions:update_mode[<submission_reference>, <mode>]"
    abort usage_message if submission_reference.blank? || mode.blank?

    Submission.find_by(reference: submission_reference).update!(mode: mode)
    Rails.logger.info "Updated submission #{submission_reference} mode to #{mode}"
  end

  desc "List submissions without mode"
  task :list_submissions_without_mode, [] => :environment do |_, _|
    submission_references = Submission.where(mode: nil).map(&:reference).join(", ")
    Rails.logger.info "Submissions with no mode set: #{submission_references}"
  end
end
