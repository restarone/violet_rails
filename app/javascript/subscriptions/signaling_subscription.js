// importing 'cable' in typical way from @hotwired/turbo-rails attempts to register "turbo-frame" element multiple times. Due to this, imported cable in a peculiar way.
// This is fixed in newer version but breaks the API's "search by properties" functionality.
import * as cable from '@hotwired/turbo-rails/app/javascript/turbo/cable'

export default class SignalingSubscription {
  constructor({ delegate, id, clientId }) {
    this.callbacks = {}
    this.delegate = delegate
    this.id = id
    this.clientId = clientId
  }

  async start () {
    const self = this

    this.subscription = await cable.subscribeTo({
      channel: 'SignalingChannel',
      id: this.id
    }, {
      received (data) {
        const { to, from, type, description, candidate } = data
        if (to != self.clientId) return

        if (description) return self.delegate.sdpDescriptionReceived({ from, description })
        if (candidate) return self.delegate.iceCandidateReceived({ from, candidate })
        if (type === 'restart') return self.delegate.negotiationRestarted({ from })
      }
    })

    this.started = true
  }

  signal (data) {
    if (!this.started) return
    this.subscription.perform('signal', data)
  }
}
