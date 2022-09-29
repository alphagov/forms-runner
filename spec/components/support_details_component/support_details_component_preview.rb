class SupportDetailsComponent::SupportDetailsComponentPreview < ViewComponent::Preview
  def without_contact_details
    contact_details = OpenStruct.new({ email: nil, phone: nil, url: nil, url_text: nil })

    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_only_phone
    contact_details = OpenStruct.new({ email: nil, phone: "Call 01610123456\n\nThis line is only open on Tuesdays.", url: nil, url_text: nil })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_only_email
    contact_details = OpenStruct.new({ email: "help@example.gov.uk", phone: nil, url: nil, url_text: nil })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_only_url_fields
    contact_details = OpenStruct.new({ email: nil, phone: nil, url: "https://example.gov.uk/contact", url_text: "Contact form" })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_email_and_phone
    contact_details = OpenStruct.new({ email: "help@example.gov.uk", phone: "Call 01610123456\n\nThis line is only open on Tuesdays.", url: nil, url_text: nil })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_email_and_url_fields
    contact_details = OpenStruct.new({ email: "help@example.gov.uk", phone: nil, url: "https://example.gov.uk/contact", url_text: "Contact form" })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_phone_and_url_fields
    contact_details = OpenStruct.new({ email: nil, phone: "Call 01610123456\n\nThis line is only open on Tuesdays.", url: "https://example.gov.uk/contact", url_text: "Contact form" })
    render(SupportDetailsComponent::View.new(contact_details))
  end

  def with_all_fields
    contact_details = OpenStruct.new({ email: "help@example.gov.uk", phone: "Call 01610123456\n\nThis line is only open on Tuesdays.", url: "https://example.gov.uk/contact", url_text: "Contact form" })
    render(SupportDetailsComponent::View.new(contact_details))
  end
end
