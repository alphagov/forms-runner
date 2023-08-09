require "spec_helper"

require_relative "../../app/lib/redis_config"

RSpec.describe RedisConfig do
  let(:redis_url_env) { nil }

  before do
    allow(ENV).to receive(:fetch).with("REDIS_URL", nil).and_return(redis_url_env)
  end

  context "when REDIS_URL is set" do
    let(:redis_url_env) { "redis_url_value" }

    it "equals REDIS_URL" do
      expect(described_class.redis_url).to eq("redis_url_value")
    end
  end

  context "when no redis url is set" do
    it "is nil" do
      expect(described_class.redis_url).to be_nil
    end
  end
end
