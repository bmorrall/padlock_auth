class AuthorizedChannel < ApplicationCable::Channel
  def subscribed
    if padlock_authorized? "channel"
      stream_from "authorized_stream"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
