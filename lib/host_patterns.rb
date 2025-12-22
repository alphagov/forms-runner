module HostPatterns
  DEFAULT_HOST_PATTERNS = [
    /submit\.forms\.service\.gov\.uk/,
    /submit\.[^.]*\.forms\.service\.gov\.uk/,
    /submit\.internal.[^.]*\.forms\.service\.gov\.uk/,
    /pr-[^.]*\.submit\.review\.forms\.service\.gov\.uk/,
  ].freeze

  def self.allowed_host_patterns
    additional_patterns = ENV.fetch("ALLOWED_HOST_PATTERNS", "").split(",").map { |pattern| Regexp.new(pattern.strip) }

    [*DEFAULT_HOST_PATTERNS, *additional_patterns]
  end
end
