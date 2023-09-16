class RoomsController < ApplicationController
  def show
    @client = Client.new(id: SecureRandom.uuid)
    cookies.encrypted[:client_id] = @client.id
    @room = Room.new(id: params[:id])
  end
end
