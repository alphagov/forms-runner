module FeatureService
  class FormRequiredError < StandardError; end

  def self.enabled?(feature_name, form = nil)
    return false if Settings.features.blank?

    segments = feature_name.to_s.split(".")
    feature = Settings.features.dig(*segments)

    return feature unless feature.is_a? Config::Options

    return true if feature.enabled

    if feature.enabled_for_form_ids.present?
      raise FormRequiredError, "Feature #{feature_name} requires form to be provided" if form.blank?

      return feature.enabled_for_form_ids == form.id if feature.enabled_for_form_ids.is_a?(Integer)

      form_ids = feature.enabled_for_form_ids.split(",").collect(&:strip)

      return form_ids.include?(form.id.to_s)
    end

    feature.enabled
  end
end
