class RoomsController < ApplicationController
  def new
  end

  def create
    redirect_to room_path(SecureRandom.uuid)
  end

  def show
    @room = Room.new(id: params[:id])
  end
end