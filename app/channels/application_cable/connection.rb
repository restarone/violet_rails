module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_client

    def connect
      self.current_client = find_client
      bind_user_to_client(self.current_client)
      bind_visit_to_client((self.current_client))
    end

    private

    def bind_visit_to_client(client)
      if cookies[:cookies_accepted]
        client.visit_id = cookies[:ahoy_visitor]
        client.visitor_id = cookies[:ahoy_visit]
      end
    end

    def bind_user_to_client(client)
      user = env['warden']&.user
      if user
        client.user_id = user.id
      else
        nil
      end
    end

    def find_client
      Client.new(id: cookies.encrypted[:client_id])
    end
  end
end
