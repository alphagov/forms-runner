# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :check_service_unavailable
  before_action :set_request_id
  after_action :add_robots_header

  def accessibility_statement; end

  def cookies; end

  def check_service_unavailable
    if ENV["SERVICE_UNAVAILABLE"].present?
      render "errors/service_unavailable", status: :service_unavailable, formats: :html
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:host] = request.host
    payload[:request_id] = request.request_id
    payload[:form_id] = params[:form_id] if params[:form_id].present?
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
end
