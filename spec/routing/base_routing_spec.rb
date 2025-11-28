require "rails_helper"

RSpec.describe Forms::BaseController, type: :routing do
  describe "routing" do
    describe "#form_id" do
      it "routes to #redirect_to_friendly_url_start" do
        expect(get: form_id_path(mode: "form", form_id: 999)).to route_to("forms/base#redirect_to_friendly_url_start", mode: "form", form_id: "999")
      end

      it "does not route for an invalid form_id" do
        expect { form_id_path(mode: "form", form_id: "invalid") }.to raise_error(ActionController::UrlGenerationError)
      end

      it "does not route for an invalid mode" do
        expect { form_id_path(mode: "invalid", form_id: 999) }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    describe "#form" do
      it "routes to #redirect_to_friendly_url_start" do
        expect(get: form_path(mode: "form", form_id: 999, form_slug: "valid-slug")).to route_to("forms/base#redirect_to_friendly_url_start", mode: "form", form_id: "999", form_slug: "valid-slug")
      end

      it "does not route for an invalid form_id" do
        expect { form_path(mode: "form", form_id: "invalid", form_slug: "valid-slug") }.to raise_error(ActionController::UrlGenerationError)
      end

      it "does not route for an invalid mode" do
        expect { form_path(mode: "invalid", form_id: 999, form_slug: "valid-slug") }.to raise_error(ActionController::UrlGenerationError)
      end

      it "does not route for an invalid form_slug" do
        expect { form_path(mode: "form", form_id: 999, form_slug: "invalid~slug") }.to raise_error(ActionController::UrlGenerationError)
      end
    end
  end
end
