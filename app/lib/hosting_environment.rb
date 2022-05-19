module HostingEnvironment
  TEST_ENVIRONMENTS = %w[development test].freeze

  def self.environment_name
    ENV.fetch("HOSTING_ENVIRONMENT_NAME", "unknown-environment")
  end

  def self.development?
    environment_name == "development"
  end

  def self.staging?
    environment_name == "staging"
  end

  def self.production?
    environment_name == "production"
  end

  def self.sandbox_mode?
    ENV.fetch("SANDBOX", "false") == "true"
  end

  def self.test_environment?
    TEST_ENVIRONMENTS.include?(HostingEnvironment.environment_name)
  end
end
