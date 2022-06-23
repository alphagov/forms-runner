# frozen_string_literal: true

class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
  after_action :add_robots_header

private

  def add_robots_header
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end
end
