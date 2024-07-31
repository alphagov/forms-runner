require "rails_helper"
require_relative "./shared_examples/repository_examples"

describe FormDirect do
  subject(:repository) { described_class }

  it_behaves_like "a form repository"
end
