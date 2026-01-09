require "net/http"

class FormMetricsService
  PREFIX = "/api/v2".freeze

  class << self
    def record_form_started(form_id:)
      path = "#{PREFIX}/forms/#{form_id}/metrics/started"
      make_request(path)
    end

    def record_form_submitted(form_id:)
      path = "#{PREFIX}/forms/#{form_id}/metrics/submitted"
      make_request(path)
    end

  private

    def make_request(path)
      uri = URI.join(Settings.forms_api.base_url, path)
      response = Net::HTTP.post(uri, "")
      if response.code.to_i >= 400
        raise "Failed to make POST request to increment form metrics to #{uri}: #{response.code} #{response.message}"
      end
    end
  end
end
