require "rails_helper"

RSpec.describe Store::DatabaseAnswerStore do
  include Store::Access

  subject(:answer_store) { described_class.new(answers) }

  let(:step) { build :step }
  let(:answer) { "test answer" }
  let(:answers) { { page_key(step) => answer, "1111" => "another answer" } }

  it_behaves_like "an answer store"

  describe "#get_stored_answer" do
    context "when the answer was stored using the database_id as the key" do
      let(:external_id) { "abc123" }
      let(:database_id) { "123487" }
      let(:answer) { "test answer" }
      let(:answers) { { database_id.to_s => answer, "1111" => "another answer" } }

      context "when the step has a database_id" do
        let(:step) { instance_double(Step, { page_id: external_id, database_id: }) }

        it "gets the answer by the database ID" do
          expect(answer_store.get_stored_answer(step)).to eq(answer)
        end
      end

      context "when the step does not have a database_id" do
        let(:step) { instance_double(Step, { page_id: external_id, database_id: nil }) }

        it "returns nil" do
          expect(answer_store.get_stored_answer(step)).to be_nil
        end
      end
    end

    context "when there are answers stored using both the id and database_id of the step" do
      let(:external_id) { "abc123" }
      let(:database_id) { "123487" }
      let(:answer) { "test answer" }
      let(:step) { instance_double(Step, { page_id: external_id, database_id: }) }
      let(:answers) { { database_id.to_s => "an answer we will ignore", external_id => answer } }

      it "returns the answer stored using the step id" do
        expect(answer_store.get_stored_answer(step)).to eq(answer)
      end
    end
  end
end
