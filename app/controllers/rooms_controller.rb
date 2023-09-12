class RoomsController < ApplicationController
  def create
    redirect_to room_path(SecureRandom.uuid)
  end

  def show
    @client = Client.new(id: SecureRandom.uuid)
    cookies.encrypted[:client_id] = @client.id
    @room = Room.new(id: params[:id])
  end
end
