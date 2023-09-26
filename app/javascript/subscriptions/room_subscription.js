// importing 'cable' in typical way from @hotwired/turbo-rails attempts to register "turbo-frame" element multiple times. Due to this, imported cable in a peculiar way.
// This is fixed in newer version but breaks the API's "search by properties" functionality.
import * as cable from '@hotwired/turbo-rails/app/javascript/turbo/cable'

export default class RoomSubscription {
  constructor ({ delegate, id, clientId }) {
    this.delegate = delegate
    this.id = id
    this.clientId = clientId
  }

  async start () {
    const self = this

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

        if (data.type === 'ping') self.delegate.roomPinged(data)
      }
    })

    this.started = true
  }

  greet (data) {
    if (!this.started) return
    this.subscription.greet(data)
  }
}
