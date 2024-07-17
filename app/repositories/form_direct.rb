class FormDirect
  include ActiveModel::Model
  include ActiveModel::Attributes
  include FormRepository

  def initialize(attributes = {})
    @attributes = attributes

    @attributes["pages"] = attributes["pages"].map { |page_data| Page.new(page_data) }
  end

  def self.find_with_mode(id:, mode:)
    raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

    return find_draft(id) if mode.preview_draft?
    return find_archived(id) if mode.preview_archived?
    return find_live(id) if mode.live?

    find_live(id) if mode.preview_live?
  end

  def self.find_live(id)
    find_request(id, "live")
  end

  def self.find_draft(id)
    find_request(id, "draft")
  end

  def self.find_archived(id)
    find_request(id, "archived")
  end

  def self.find_request(id, mode)
    url = URI.parse("#{Settings.forms_api.base_url}/api/v1/forms/#{id}/#{mode}")

    # Create the HTTP GET request
    request = Net::HTTP::Get.new(url.to_s)
    request["X-API-Token"] = Settings.forms_api.auth_key

    # Create an HTTP session
    response = Net::HTTP.start(url.host, url.port) do |http|
      http.request(request)
    end

    # Check the response status code
    case response
    when Net::HTTPSuccess
      # Parse and return the JSON response
      FormDirect.new(JSON.parse(response.body))
    else
      # Handle non-successful responses
      raise "HTTP request failed with code #{response.code}: #{response.message}"
    end
  end
end
