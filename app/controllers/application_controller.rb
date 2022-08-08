# frozen_string_literal: true

class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
  before_action :check_service_unavailable
  after_action :add_robots_header

  def check_service_unavailable
    if ENV["SERVICE_UNAVAILABLE"].present?
      render "errors/service_unavailable", status: :service_unavailable, formats: :html
    end
  end

private

  def add_robots_header
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end
end
