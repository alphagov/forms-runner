RSpec.shared_examples "an answer store" do |_parameter|
  describe "#get_stored_answer" do
    it "responds with the answer for the step" do
      expect(answer_store.get_stored_answer(step)).to eq(answer)
    end
  end
end
