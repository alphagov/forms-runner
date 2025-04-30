Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    Settings.auth0.client_id,
    Settings.auth0.client_secret,
    Settings.auth0.domain,
    callback_path: "/auth/auth0/callback",
    authorize_params: {
      scope: "openid profile",
    },
  )
end
