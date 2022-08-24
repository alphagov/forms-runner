require_relative "../../app/lib/redis_config"

redis_url = RedisConfig.redis_url

if redis_url.blank?
  throw StandardError.new "You must configure a session store using REDIS_URL or VCAP_SERVICES" unless Rails.configuration.try(:unsafe_session_storage)
  STDERR.write "WARNING: Using cookies as session store, insecure\n"
else
  Rails.application.config.session_store :redis_session_store,
    key: "_forms",
    redis: {
      url: redis_url,
      ttl: 20.hours, # set the redis ttl to 20 hours, but the cookie expiry will still be session
      key_prefix: "session:"
    },
    on_redis_down: ->(_e, _env, _sid) { Rails.logger.warn "Unable to connect to Redis session store." },
    serializer: :json

    STDERR.write "Using redis as session store\n"
end
