class FormDirect
  include ActiveModel::Model
  include ActiveModel::Attributes
  include FormRepository

  def self.find_with_mode(id:, mode:)
    raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

    form_body = find_request(id, mode)

    form_body["pages"] = form_body["pages"]&.map { |page_data| Page.from_json(page_data) }

    Form.new(form_body)
  end

  def self.find_request(id, mode)
    url = URI.parse("#{Settings.forms_api.base_url}/api/v1/forms/#{id}/#{mode}")

    # Create the HTTP GET request
    request = Net::HTTP::Get.new(url.to_s)
    request["X-API-Token"] = Settings.forms_api.auth_key
    request["Accept"] = "application/json"

    # Create an HTTP session
    response = Net::HTTP.start(url.host, url.port) do |http|
      http.request(request)
    end

    # Check the response status code
    case response
    when Net::HTTPSuccess
      # Parse and return the JSON response
      JSON.parse(response.body)
    else
      # Handle non-successful responses
      raise "HTTP request failed with code #{response.code}: #{response.message}"
    end
  end
end
