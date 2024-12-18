class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = find_room
    stream_for @room
    broadcast_to @room, { type: 'ping', from: params[:client_id] }
  end

  def unsubscribed
    Turbo::StreamsChannel.broadcast_remove_to(
      find_room,
      target: "medium_#{current_client.id}"
    )
  end

  def greet(data)
    user = User.find_by(id: current_client.user_id)
    Turbo::StreamsChannel.broadcast_append_to(
      data['to'],
      target: 'media',
      partial: 'media/medium',
      locals: { client_id: data['from'], user:  user}
    )
  end

  private

  def find_room
    Room.new(id: params[:id])
  end
end
