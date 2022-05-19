require "rails_helper"

RSpec.describe Form, type: :model do
  it "initializes correctly" do
    expect(Form.new({id: 1, name: "form name", submission_email: "user@example.com"})).to have_attributes({id: 1, name: "form name", submission_email: "user@example.com"})
  end

  it "initializes correctly" do
    expect{Form.new({id: 1, name: "form name", submission_email: "user@example.com", extra_field: 'hetsh'})}.to raise_error
  end
end
