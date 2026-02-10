# config/initializers/omniauth.rb
#
OmniAuth.config.logger = Rails.logger
OmniAuth.config.logger.level = Logger::DEBUG

private_key_pem = ENV.fetch("GOVUK_ONE_LOGIN_PRIVATE_KEY", "")
# decode the private key from base64
private_key_pem = Base64.decode64(private_key_pem)
private_key_pem = private_key_pem.gsub('\n', "\n")

private_key = OpenSSL::PKey::RSA.new(private_key_pem)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :govuk_one_login, {
    name: :govuk_one_login,
    client_id: ENV["GOVUK_ONE_LOGIN_CLIENT_ID"], # your client ID from the GOV.UK One Login admin tool
    idp_base_url: ENV["GOVUK_ONE_LOGIN_BASE_URL"],
    private_key: private_key, # the private key you generated above in PEM format
    redirect_uri: ENV["GOVUK_ONE_LOGIN_REDIRECT_URI"], # if this is a relative URI, the requesting domain will be used
    # these are optional - shown here with their default values if omitted
    private_key_kid: "", # the key ID of the private key being used - if using a JWKS endpoint, this must be set for authorization to work
    signing_algorithm: "ES256", # the algorithm used to encode and decode the JWT - RS256 is also supported
    scope: "openid email", # comma-separated; must include at least `openid` and `email`
    ui_locales: "en", # comma-separated; can also include `cy` for Welsh UI
    vtr: ["Cl.Cm"], # array with one element; dot-separated; can also include identity vectors such as `P2` (eg. `Cl.Cm.P2`)
    pkce: false, # set to `true` to enable "Proof Key for Code Exchange"
    userinfo_claims: [], # array of URLs; see https://docs.sign-in.service.gov.uk/integrate-with-integration-environment/authenticate-your-user/#create-a-url-encoded-json-object-for-lt-claims-request-gt
  }

  # will call `Users::OmniauthController#failure` if there are any errors during the login process
  # on_failure { |env| Users::OmniauthController.action(:failure).call(env) }
end
