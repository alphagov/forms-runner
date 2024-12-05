require "rails_helper"

RSpec.describe Question::File, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  it_behaves_like "a question model"
end
