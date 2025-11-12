require_relative "../../app/lib/redis_config"

redis_url = RedisConfig.redis_url

if redis_url.blank?
  throw StandardError.new "You must configure a session store using REDIS_URL" unless Rails.configuration.try(:unsafe_session_storage)

  Rails.application.config.session_store :cache_store
  Rails.logger.warn "WARNING: Using Rails cache #{Rails.application.config.cache_store.inspect || ":file_store"} as session store, this is insecure and session data may be lost on server restart\n"
else
  Rails.application.config.session_store :redis_session_store,
                                         key: "_forms",
                                         redis: {
                                           url: redis_url,
                                           ttl: 20.hours, # set the redis ttl to 20 hours, but the cookie expiry will still be session
                                           key_prefix: "session:",
                                         },
                                         on_redis_down: ->(_e, _env, _sid) { Rails.logger.warn "Unable to connect to Redis session store." },
                                         serializer: :json

  Rails.logger.debug "Using redis as session store\n"
end
