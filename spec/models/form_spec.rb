require 'rails_helper'

RSpec.describe Form, :type => :model do
  before(:each) do
    @respose_data  = { :person => {"id"=>1, "name"=>"form name", "submission_email"=>"user@example.com"} }.to_json
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/1", {}, @respose_data , 200
    end
  end

  it "returns a simple form" do
    expect(described_class.find(1).id).to eq 1
  end
end
#
