import { cable } from '@hotwired/turbo-rails'

export default class WebrtcSessionSubscription {
  constructor({ controller, id, clientId }) {
    this.callbacks = {}
    this.controller = controller
    this.id = id
    this.clientId = clientId
  }

  async start () {
    const self = this

    this.subscription = await cable.subscribeTo({
      channel: 'WebrtcSessionChannel',
      id: this.id
    }, {
      received (data) {
        const { to, from, type, description, candidate } = data
        if (to != self.clientId) return

        self.broadcast(type, data)

        const negotiation = self.controller.negotiationFor(from)
        if (description) return negotiation.setDescription(description)
        if (candidate) return negotiation.addCandidate(candidate)
      }
    })

    this.started = true
  }

  signal (data) {
    if (!this.started) return
    this.subscription.perform('signal', data)
  }

  on (name, callback) {
    const names = name.split(' ')
    names.forEach((name) => {
      this.callbacks[name] = this.callbacks[name] || []
      this.callbacks[name].push(callback)
    })
  }

  broadcast (name, data) {
    (this.callbacks[name] || []).forEach(
      callback => callback.call(null, { type: name, detail: data })
    )
  }

  off (name) {
    if (name) return delete this.callbacks[name]
    else this.callbacks = {}
  }
}
