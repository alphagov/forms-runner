require "rails_helper"

RSpec.describe Store::DatabaseAnswerStore do
  include Store::Access

  subject(:answer_store) { described_class.new(answers) }

  let(:step) { build :step }
  let(:answer) { "test answer" }
  let(:answers) { { page_key(step) => answer, "1111" => "another answer" } }

  it_behaves_like "an answer store"
end
