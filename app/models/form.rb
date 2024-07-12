class Form
  include ActiveModel::Model
  include ActiveModel::Attributes

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
  attribute :live_at, default: "invalid_date"
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
  attribute :state

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
