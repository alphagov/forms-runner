module Question::File::VirusScan
  NO_THREATS_FOUND_SCAN_STATUS = "NO_THREATS_FOUND".freeze
  THREATS_FOUND_SCAN_STATUS = "THREATS_FOUND".freeze

  def check_scan_result(key)
    scan_status = Question::FileUploadS3Service.new.poll_for_scan_status(key)
    return if scan_status == NO_THREATS_FOUND_SCAN_STATUS

    if scan_status == THREATS_FOUND_SCAN_STATUS
      errors.add(:file, :contains_virus)
      return
    end

    errors.add(:file, :scan_failure)
  rescue Question::FileUploadS3Service::PollForScanResultTimeoutError
    errors.add(:file, :scan_failure)
    FileUploadLogger.log_s3_operation_error(key, "Timed out polling for GuardDuty scan status for uploaded file")
  end
end
