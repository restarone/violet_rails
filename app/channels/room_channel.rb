class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = find_room
    stream_for @room
    @room.update(participant_count: (@room.participant_count + 1))
    broadcast_to @room, { type: 'ping', from: params[:client_id] }
  end

  def unsubscribed
    Turbo::StreamsChannel.broadcast_remove_to(
      find_room,
      target: "medium_#{current_client.id}"
    )
    @room.update(participant_count: (@room.participant_count + -1))
    Turbo::StreamsChannel.broadcast_replace_to(
      target: 'room-stats',
      partial: 'rooms/participants',
      locals: { room: find_room }
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
    Turbo::StreamsChannel.broadcast_replace_to(
      data['to'],
      target: 'room-stats',
      partial: 'rooms/participants',
      locals: { room: find_room }
    )
  end

  private

  def find_room
    Room.find_by(external_room_id: params[:id])
  end
end
