module FeatureService
  class FormRequiredError < StandardError; end

  def self.enabled?(feature_name, form = nil)
    return false if Settings.features.blank?

    segments = feature_name.to_s.split(".")
    feature = Settings.features.dig(*segments)

    return feature unless feature.is_a? Config::Options

    if feature.forms.present?
      raise FormRequiredError, "Feature #{feature_name} requires form to be provided" if form.blank?

      form_key = form.id.to_s.underscore.to_sym
      return feature.forms[form_key] if feature.forms.key?(form_key)
    end

    feature.enabled
  end
end
