export default class Client {
  constructor (id) {
    this.callbacks = {}
    this.id = id
  }

  get peerConnection () {
    return this.negotiation && this.negotiation.peerConnection
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