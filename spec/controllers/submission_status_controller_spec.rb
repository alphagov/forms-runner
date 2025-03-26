require "rails_helper"

RSpec.describe SubmissionStatusController do
  describe "#status" do
    context "when authorization token is included in request" do
      let(:token) { "test_token" }

      before do
        request.headers["Authorization"] = "Bearer #{token}"
      end

      context "when a submission has been emailed" do
        it "returns a 204 status" do
          submission = Submission.create!(reference: "123", mail_message_id: "456")

          get :status, params: { reference: submission.reference }

          expect(response).to have_http_status :no_content
        end
      end

      context "when a submission has not been emailed" do
        it "returns a 404 status" do
          submission = Submission.create!(reference: "789")

          get :status, params: { reference: submission.reference }

          expect(response).to have_http_status :not_found
        end
      end

      context "when a submission does not exist" do
        it "returns a 404 status" do
          get :status, params: { reference: "999" }

          expect(response).to have_http_status :not_found
        end
      end
    end

    context "when no authorization token is included in request" do
      it "returns a 401 status" do
        get :status, params: { reference: "123" }

        expect(response).to have_http_status :unauthorized
      end
    end
  end

  context "when authorization token is invalid" do
    let(:token) { "bad_token" }

    before do
      request.headers["Authorization"] = "Bearer #{token}"
    end

    it "returns a 401 status" do
      get :status, params: { reference: "123" }

      expect(response).to have_http_status :unauthorized
    end
  end
end
