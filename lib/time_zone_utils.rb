module TimeZoneUtils
  def self.submission_time_zone
    Rails.configuration.x.submission.time_zone || "UTC"
  end
end
