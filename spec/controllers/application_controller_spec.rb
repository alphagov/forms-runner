require "rails_helper"

RSpec.describe ApplicationController do
  controller do
    rescue_from RuntimeError do |e|
      log_rescued_exception(e)
      render "errors/internal_server_error", status: :internal_server_error
    end

    def raise_error
      raise "oh no\nwhat happened"
    end

    def raise_error_with_cause
      raise "inner error"
    rescue RuntimeError
      raise "outer error"
    end
  end

  before do
    routes.draw do
      get "raise_error" => "anonymous#raise_error"
      get "raise_error_with_cause" => "anonymous#raise_error_with_cause"
    end
  end

  specify "anonymous controller" do
    get :raise_error
    expect(response).to have_http_status :internal_server_error
  end

  describe "adding exception to logging context" do
    it "adds rescued exception to logging context" do
      get :raise_error

      expect(controller.logging_context).to include(rescued_exception: ["RuntimeError", "oh no\nwhat happened"])
    end
  end

  describe "logging exception" do
    let(:output) { StringIO.new }
    let(:logger) do
      Logger.new(output).tap do |logger|
        logger.formatter = JsonLogFormatter.new
      end
    end

    before do
      Rails.logger.broadcast_to logger
    end

    after do
      Rails.logger.stop_broadcasting_to logger
    end

    it "logs rescued exceptions as warnings" do
      get :raise_error

      expect(output.string.lines.first)
        .to include('"level":"WARN"')
        .and include('Rescued exception:\n  \nRuntimeError (oh no\nwhat happened)')
    end

    it "logs causes of rescued exceptions" do
      get :raise_error_with_cause

      expect(output.string.lines.first)
        .to include('"level":"WARN"')
        .and include('RuntimeError (outer error):\n\nCauses:\nRuntimeError (inner error)')
    end
  end

  describe "sending exception to Sentry" do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it "captures the exception" do
      get :raise_error

      expect(Sentry).to have_received(:capture_exception)
    end
  end
end
