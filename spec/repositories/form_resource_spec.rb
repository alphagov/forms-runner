describe FormResource do
  describe "#find_with_mode" do
    context "when mode is live" do
      let(:response_data) { { id: 1, name: "form name", live_at: "2022-08-18 09:16:50Z" }.to_json }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v1/forms/1/live", req_headers, response_data, 200
        end
      end

      it "returns a live form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("live"))

        expect(form).to have_attributes(id: 1, name: "form name")
        expect(form.live?).to eq(true)
      end
    end

    context "when mode is draft" do
      let(:response_data) { { id: 1, name: "form name", live_at: nil }.to_json }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v1/forms/1/draft", req_headers, response_data, 200
        end
      end

      it "returns a draft form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-draft"))

        expect(form).to have_attributes(id: 1, name: "form name")
        expect(form.live?).to eq(false)
      end
    end
  end
end
