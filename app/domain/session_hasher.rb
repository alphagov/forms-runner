class SessionHasher
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def request_to_session_hash
    if request&.session && request.session.id
      Digest::SHA256.hexdigest(request.session.id.to_s)
    end
  end
end
