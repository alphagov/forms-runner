class RedisConfig
  REDIS_ATTRS = [:redis].freeze
  REDIS_URL = REDIS_ATTRS + [0, :credentials, :uri]

  def self.redis_url
    ENV.fetch("REDIS_URL", nil)
  end
end
