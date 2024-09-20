class FeatureService
  class << self
    def enabled?(feature_name)
      return false if Settings.features.blank?

      segments = feature_name.to_s.split(".")
      Settings.features.dig(*segments)
    end
  end
end
