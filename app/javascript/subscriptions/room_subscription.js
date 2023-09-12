import { cable } from '@hotwired/turbo-rails'

export default class RoomSubscription {
  constructor ({ controller, id, clientId }) {
    this.controller = controller
    this.id = id
    this.clientId = clientId
  }

  async start () {
    const self = this
    const controller = this.controller

    this.subscription = await cable.subscribeTo({
      channel: 'RoomChannel',
      id: this.id,
      client_id: this.clientId
    }, {
      greet (data) {
        this.perform('greet', data)
      },

      received (data) {
        // Ignore self-sent data
        if (data.from === self.clientId) return

        if (data.type === 'ping') controller.greetNewClient(data)
      }
    })

    this.started = true
  }

  greet (data) {
    if (!this.started) return
    this.subscription.greet(data)
  }
}
