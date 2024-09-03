require "net/sftp"

class SftpService
  def upload(file_path, form_id, timestamp, submission_reference)
    Net::SFTP.start("localhost", "test", password: "", port: 2222) do |sftp|
      remote_path = remote_file_path(form_id, timestamp, submission_reference)
      sftp.upload!(file_path, remote_path)
      Rails.logger.info "Uploaded submission to SFTP with path: #{remote_path}"
    end
  end

  def remote_file_path(form_id, timestamp, submission_reference)
    "#{timestamp.iso8601}_#{submission_reference}.csv"
  end
end
