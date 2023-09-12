module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :current_client

    def connect
      self.current_client = find_client
    end

    private

    def find_client
      Client.new(id: cookies.encrypted[:client_id])
    end
  end
end
