RSpec.shared_examples "a form repository" do |_parameter|
  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  describe "#find_with_mode" do
    context "when mode is live" do
      let(:response_data) { { id: 1, name: "form name", live_at: "2022-08-18 09:16:50Z" }.to_json }

      before do
        stub_request(:get, "#{Settings.forms_api.base_url}/api/v1/forms/1/live")
          .with(headers: req_headers)
          .to_return_json(body: response_data)
      end

      it "returns a live form" do
        form = described_class.find_with_mode(id: 1, mode: "live")

        expect(form).to have_attributes(id: 1, name: "form name")
        expect(form.live?).to eq(true)
      end
    end

    context "when mode is draft" do
      let(:response_data) { { id: 1, name: "form name", live_at: nil }.to_json }

      before do
        stub_request(:get, "#{Settings.forms_api.base_url}/api/v1/forms/1/draft")
          .with(headers: req_headers)
          .to_return_json(body: response_data)
      end

      it "returns a draft form" do
        form = described_class.find_with_mode(id: 1, mode: "draft")

        expect(form).to have_attributes(id: 1, name: "form name")
        expect(form.live?).to eq(false)
      end
    end
  end
end
