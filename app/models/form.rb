class Form < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/"
  self.include_format_in_path = false

  has_many :pages
  attr_accessor :document_json

  def last_page
    pages.find { |p| !p.has_next_page? }
  end

  def page_by_id(page_id)
    pages.find { |p| p.id == page_id.to_i }
  end

  def payment_url_with_reference(reference)
    return nil if payment_url.blank?

    "#{payment_url}?reference=#{reference}"
  end

  def support_details
    OpenStruct.new({
      email: support_email,
      phone: support_phone,
      call_charges_url: "https://www.gov.uk/call-charges",
      url: support_url,
      url_text: support_url_text,
    })
  end
end
