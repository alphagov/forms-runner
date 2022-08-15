class EventLogger
  def self.log(tag, object)
    Rails.logger.info "[#{tag}] #{object.to_json}"
  end
end
