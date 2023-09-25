class SignalingChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.find_by(external_room_id: params[:id])
  end

  def signal(data)
    broadcast_to(Room.find_by(external_room_id: params[:id]), data)
  end
end
