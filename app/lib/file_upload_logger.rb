class FileUploadLogger
  S3_OBJECT_KEY_FIELD = :s3_object_key

  def self.log_s3_operation(object_key, message, additional_context = {})
    Rails.logger.info(message, additional_context.merge({ S3_OBJECT_KEY_FIELD => object_key }))
  end

  def self.log_s3_operation_error(object_key, message, additional_context = {})
    Rails.logger.error(message, additional_context.merge({ S3_OBJECT_KEY_FIELD => object_key }))
  end
end
