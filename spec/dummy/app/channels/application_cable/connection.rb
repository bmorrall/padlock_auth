module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :access_token_subject

    def connect
      self.access_token_subject = find_verified_subject
    end

    private

    def find_verified_subject
      if padlock_authorized? "action_cable"
        padlock_auth_token.subject
      else
        reject_unauthorized_connection
      end
    end
  end
end
