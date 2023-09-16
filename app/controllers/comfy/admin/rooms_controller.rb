class Comfy::Admin::RoomsController < Comfy::Admin::Cms::BaseController
  def new
    render 'rooms/new'
  end

  def create
    redirect_to room_path(SecureRandom.uuid)
  end
end
