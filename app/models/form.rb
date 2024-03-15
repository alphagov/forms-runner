class Form < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v1/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  has_many :pages

  def self.find_live(id)
    find(:one, from: "#{prefix}forms/#{id}/live")
  end

  def self.find_draft(id)
    find(:one, from: "#{prefix}forms/#{id}/draft")
  end

  def self.find_archived(id)
    find(:one, from: "#{prefix}forms/#{id}/archived")
  end

  def last_page
    pages.find { |p| !p.has_next_page? }
  end

  def page_by_id(page_id)
    pages.find { |p| p.id == page_id.to_i }
  end

  def live?(current_datetime = Time.zone.now)
    return false if respond_to?(:live_at) && live_at.blank?
    raise Date::Error, "invalid live_at time" if live_at_date.nil?

    live_at_date < current_datetime.to_time
  end

  def live_at_date
    try(:live_at).try(:to_time)
  end

  def payment_url_with_reference(reference)
    return nil if payment_url.blank?

    "#{payment_url}?reference=#{reference}"
  end
end
