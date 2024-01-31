# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_request_id
  before_action :set_logging_context
  before_action :check_maintenance_mode_is_enabled
  after_action :add_robots_header

  add_flash_types :email_sent

  def accessibility_statement; end

  def cookies; end

  # Because determining the clients real IP is hard, simply return the first
  # value of the x-forwarded_for, checking it's an IP. This will probably be
  # enough for our basic monitoring
  def user_ip(forwarded_for = "")
    first_ip_string = forwarded_for.split(",").first
    Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]).match(first_ip_string) && first_ip_string
  end

  def check_maintenance_mode_is_enabled
    if Settings.maintenance_mode.enabled && non_maintenance_bypass_ip_address?
      redirect_to maintenance_page_path
    end
  end

  def logging_context
    @logging_context ||= {}
  end

  def set_logging_context
    @logging_context = {}.tap do |h|
      h[:host] = request.host
      h[:request_id] = request.request_id
      h[:form_id] = params[:form_id] if params[:form_id].present?
      h[:page_id] = params[:page_slug] if params[:page_slug].present? && params[:page_slug].match(Page::PAGE_ID_REGEX)
      h[:page_slug] = params[:page_slug] if params[:page_slug].present?
      h[:session_id_hash] = session_id_hash
      h[:trace_id] = request.env["HTTP_X_AMZN_TRACE_ID"] if request.env["HTTP_X_AMZN_TRACE_ID"].present?
    end
  end

private

  def add_robots_header
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def set_request_id
    if Rails.env.production?
      [Form, Page].each do |active_resource_model|
        active_resource_model.headers["X-Request-ID"] = request.request_id
      end
    end
  end

  def non_maintenance_bypass_ip_address?
    bypass_ips = Settings.maintenance_mode.bypass_ips

    return true if bypass_ips.blank?

    bypass_ip_list = bypass_ips.split(",").map { |ip| IPAddr.new ip.strip }
    bypass_ip_list.none? { |ip| ip.include?(user_ip(request.env.fetch("HTTP_X_FORWARDED_FOR", ""))) }
  end

  def session_id_hash
    SessionHasher.new(request).request_to_session_hash
  end
end
