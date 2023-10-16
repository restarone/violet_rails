class RoomsController < ApplicationController
  before_action :load_room
  before_action :check_authentication, only: [:show]

  def show
    @is_room_owner = false
    @client = Client.new(id: SecureRandom.uuid)
    cookies.encrypted[:client_id] = @client.id

    if current_user
      @is_room_owner = current_user.id == @room.user_id
    end
    @user = current_user
    @visit = current_visit
  end

  private

  def check_authentication
    if @room.require_authentication
      unless current_user
        flash.alert = "you need to sign in first!"
        redirect_to new_user_session_path
      end
    end
  end

  def load_room
    @room = Room.find_by(external_room_id: params[:id])
  end
end
