class Comfy::Admin::RoomsController < Comfy::Admin::Cms::BaseController
  def new
    @room = Room.new
    render 'rooms/new'
  end

  def create
    external_room_id = SecureRandom.uuid
    Room.create!(room_params.merge(external_room_id: external_room_id, user_id: current_user.id))
    redirect_to room_path(external_room_id)
  end

  private

  def room_params
    params.require(:room).permit(
      :name,
      :active,
      :require_authentication,
      :owner_broadcast_only,
    )
  end
end
