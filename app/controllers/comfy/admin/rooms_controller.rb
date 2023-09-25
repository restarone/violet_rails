class Comfy::Admin::RoomsController < Comfy::Admin::Cms::BaseController
  def new
    render 'rooms/new'
  end

  def create
    external_room_id = SecureRandom.uuid
    Room.create!(external_room_id: external_room_id)
    redirect_to room_path(external_room_id)
  end
end
