class Form
  include ActiveModel::Model
  include ActiveModel::Attributes

  class FormRecord < ActiveResource::Base
    self.site = Settings.forms_api.base_url
    self.element_name = "form"
    self.prefix = "/api/v1/"
    self.include_format_in_path = false
    headers["X-API-Token"] = Settings.forms_api.auth_key

    has_many :pages

    def self.find_with_mode(id:, mode:)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

      return find_draft(id) if mode.preview_draft?
      return find_archived(id) if mode.preview_archived?
      return find_live(id) if mode.live?

      find_live(id) if mode.preview_live?
    end

    def self.find_live(id)
      find(:one, from: "#{prefix}forms/#{id}/live")
    end

    def self.find_draft(id)
      find(:one, from: "#{prefix}forms/#{id}/draft")
    end

    def self.find_archived(id)
      find(:one, from: "#{prefix}forms/#{id}/archived")
    end

    def to_form
      Form.new(attributes)
    end
  end

  def self.find(id)
    FormRecord.find(id)&.to_form
  end

  def self.find_with_mode(id:, mode:)
    FormRecord.find_with_mode(id: id, mode: mode)&.to_form
  end

  attribute :created_at, :datetime
  attribute :creator_id
  attribute :declaration_section_completed
  attribute :declaration_text
  attribute :form_slug
  attribute :has_draft_version
  attribute :has_live_version
  attribute :has_routing_errors
  attribute :id
  attribute :incomplete_tasks
  attribute :live_at, default: 'invalid_date'
  attribute :name
  attribute :organisation_id
  attribute :pages
  attribute :payment_url
  attribute :privacy_policy_url
  attribute :question_section_completed
  attribute :ready_for_live
  attribute :start_page
  attribute :submission_email
  attribute :support_email
  attribute :support_phone
  attribute :support_url
  attribute :support_url_text
  attribute :task_statuses
  attribute :updated_at
  attribute :what_happens_next_markdown

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
