class RoomsController < ApplicationController
  def show
    @client = Client.new(id: SecureRandom.uuid)
    cookies.encrypted[:client_id] = @client.id
    @room = Room.new(id: params[:id])

    @user = current_user
    @visit = current_visit
  end
end
