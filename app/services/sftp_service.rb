require "net/sftp"

class SftpService
  def upload(file_path, form_id, timestamp, submission_reference)
    Net::SFTP.start("localhost", "test", password: "", port: 2222) do |sftp|
      remote_dir = remote_dir_name(form_id)
      create_remote_dir(sftp, remote_dir)

      remote_path = remote_file_path(remote_dir, timestamp, submission_reference)
      sftp.upload!(file_path, remote_path, mkdir: true)
      Rails.logger.info "Uploaded submission to SFTP with path: #{remote_path}"
    end
  end

  def upload_using_public_key_auth(file_path, form_id, timestamp, submission_reference)
    private_key = ''
    Net::SFTP.start("localhost", "test", port: 2222, key_data: [private_key]) do |sftp|
      remote_dir = remote_dir_name(form_id)
      create_remote_dir(sftp, remote_dir)

      remote_path = remote_file_path(remote_dir, timestamp, submission_reference)
      sftp.upload!(file_path, remote_path, mkdir: true)
      Rails.logger.info "Uploaded submission to SFTP with path: #{remote_path}"
    end
  end

  def remote_file_path(remote_dir, timestamp, submission_reference)
    "#{remote_dir}/#{timestamp.iso8601}_#{submission_reference}.csv"
  end

  def remote_dir_name(form_id)
    "form_submissions_#{form_id}"
  end

  def create_remote_dir(sftp, remote_dir)
    return if sftp.file.directory? remote_dir

    sftp.mkdir!(remote_dir)
  end
end
