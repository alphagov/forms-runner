class HeartbeatController < ActionController::API
  def ping
    render(body: "PONG")
  end
end
