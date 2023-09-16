class SignalingChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.new(id: params[:id])
  end

  def signal(data)
    broadcast_to(Room.new(id: params[:id]), data)
  end
end
