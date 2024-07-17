require "rails_helper"

RSpec.describe Forms::PrivacyPageController, type: :request do
  let(:form) do
    build(:form, :with_pages)
  end

  describe "#show" do
    before do
      allow(FormService).to receive(:find_with_mode).with(id: form.id.to_s, mode: kind_of(Mode)).and_return(form)
      get form_privacy_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug)
    end

    it "includes the privacy policy URL" do
      expect(response.body).to include(form.privacy_policy_url)
    end

    it "renders the show privacy page template" do
      expect(response).to render_template("forms/privacy_page/show")
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end
  end
end
