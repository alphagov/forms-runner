class FormResource < ActiveResource::Base
  include FormRepository

  has_many :pages

  def self.find_with_mode(id:, mode:)
    raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

    return find_draft(id) if mode.preview_draft?
    return find_archived(id) if mode.preview_archived?
    return find_live(id) if mode.live?

    find_live(id) if mode.preview_live?
  end

  self.site = Settings.forms_api.base_url
  self.element_name = "form"
  self.prefix = "/api/v1/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  def self.find_live(id)
    find(:one, from: "#{prefix}forms/#{id}/live")
  end

  def self.find_draft(id)
    find(:one, from: "#{prefix}forms/#{id}/draft")
  end

  def self.find_archived(id)
    find(:one, from: "#{prefix}forms/#{id}/archived")
  end
end
