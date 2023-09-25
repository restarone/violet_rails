class RoomsController < ApplicationController
  def show
    @client = Client.new(id: SecureRandom.uuid)
    cookies.encrypted[:client_id] = @client.id
    @room = Room.find_by(external_room_id: params[:id])

    @user = current_user
    @visit = current_visit
  end
end
