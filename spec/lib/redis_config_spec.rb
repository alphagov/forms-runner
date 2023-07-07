require "spec_helper"

require_relative "../../app/lib/redis_config"

RSpec.describe RedisConfig do
  let(:vcap_env) { nil }
  let(:redis_url_env) { nil }

  before do
    allow(ENV).to receive(:fetch).with("VCAP_SERVICES", nil).and_return(vcap_env)
    allow(ENV).to receive(:fetch).with("REDIS_URL", nil).and_return(redis_url_env)
  end

  context "when VCAP_SERVICES is set" do
    let(:vcap_env) { File.read(File.join("spec", "fixtures", "vcap_example.json")) }

    it "extracts the uri from JSON" do
      expect(described_class.redis_url).to eq("rediss://:password@redis.example.org:6379")
    end
  end

  context "when REDIS_URL is set" do
    let(:redis_url_env) { "redis_url_value" }

    it "equals REDIS_URL" do
      expect(described_class.redis_url).to eq("redis_url_value")
    end
  end

  context "when VCAP_SERVICES and REDIS_URL are set" do
    let(:vcap_env) { File.read(File.join("spec", "fixtures", "vcap_example.json")) }
    let(:redis_url_env) { "redis_url_value" }

    it "uses the VCAP_SERVICES url" do
      expect(described_class.redis_url).to eq("rediss://:password@redis.example.org:6379")
    end
  end

  context "when no redis url is set" do
    it "is nil" do
      expect(described_class.redis_url).to be_nil
    end
  end
end
