module Question
  class File < QuestionBase
    attribute :file

    validate :file_is_allowed_size?

    def file_is_allowed_size?
      Rails.logger.info "File size is #{file.size} - valid?: #{file.size < 100.kilobytes}"
      errors.add(:file, :too_big) if file.size > 100.kilobytes
      errors
    end
  end
end
