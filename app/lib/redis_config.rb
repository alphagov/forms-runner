class RedisConfig
  # this is the key the redis details are stored in PAAS VCAP_SERVICES
  REDIS_ATTRS = [:redis].freeze
  REDIS_URL = REDIS_ATTRS + [0, :credentials, :uri]

  def self.redis_url
    return vcap_services.dig(*REDIS_URL) if vcap_services

    ENV.fetch("REDIS_URL", nil)
  end

  def self.vcap_services
    env_var = ENV.fetch("VCAP_SERVICES", nil)
    JSON.parse(env_var, symbolize_names: true) if env_var
  end
end
