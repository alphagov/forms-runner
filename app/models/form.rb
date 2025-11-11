class Form < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/"
  self.include_format_in_path = false

  class Step < ActiveResource::Base
    self.site = Form.site
    self.prefix = Form.prefix_source
    self.include_format_in_path = false
  end

  has_many :steps, class_name: "form/step"
  attr_accessor :document_json

  def form_id
    @attributes["form_id"] || @attributes["id"]
  end

  alias_method :id, :form_id

  def pages
    return @attributes["pages"] if @attributes.key? "pages"

    @pages ||= steps.map do |step|
      step = step.as_json
      attrs = {
        "id" => step["id"],
        "position" => step["position"],
        "next_page" => step["next_step_id"],
      }
      if step["type"] == "question_page"
        attrs.merge!(step["data"])
      end
      attrs["routing_conditions"] = step.fetch("routing_conditions", [])
      Page.new(attrs, @persisted)
    end
  end

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

  def submission_method
    return :email if submission_type.blank? || submission_type.start_with?("email")
    return :s3 if submission_type.start_with?("s3")

    raise "unrecognised submission method in #{submission_type.inspect}"
  end

  def submission_format
    (@attributes["submission_format"] || []).map(&:to_sym)
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
