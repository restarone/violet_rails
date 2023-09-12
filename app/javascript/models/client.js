export default class Client {
  constructor (id) {
    this.id = id
  }

  get peerConnection () {
    return this.negotiation && this.negotiation.peerConnection
  }
}