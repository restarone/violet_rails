import { Controller } from '@hotwired/stimulus'
import Client from '../models/client'
import WebrtcNegotiation from '../models/webrtc_negotiation'
import RoomSubscription from '../subscriptions/room_subscription'
import Signaller from '../subscriptions/webrtc_session_subscription'

export default class RoomController extends Controller {
  
  connect() {
    this.clients = {}
    this.client = new Client(this.clientIdValue)

    this.subscription = new RoomSubscription({
      controller: this,
      id: this.idValue,
      clientId: this.client.id
    })

    this.signaller = new Signaller({
      controller: this,
      id: this.idValue,
      clientId: this.client.id
    })

    this.signaller.on('description candidate', ({ detail: { from } }) => {
      this.startStreamingTo(this.clients[from])
    })
  }

  async enter () {
    try {
      const constraints = { audio: true, video: true }
      this.stream = await navigator.mediaDevices.getUserMedia(constraints)
      this.localMediaTarget.srcObject = this.stream
      this.enterTarget.hidden = true

      this.subscription.start()
      this.signaller.start()
    } catch (error) {
      console.error(error)
    }
  }

  greetNewClient ({ from }) {
    const otherClient = this.findOrCreateClient(from)
    otherClient.newcomer = true
    this.subscription.greet({ to: otherClient.id, from: this.client.id })
  }

  negotiateConnection ({ detail: { clientId } }) {
    const otherClient = this.findOrCreateClient(clientId)

    // Be polite to newcomers!
    const polite = !!otherClient.newcomer

    otherClient.negotiation = this.createNegotiation({
      otherClientId: otherClient.id,
      polite
    })

    // The polite client sets up the negotiation last, so we can start streaming
    // The impolite client signals to the other client that it's ready
    if (polite) {
      this.startStreamingTo(otherClient)
    } else {
      this.subscription.greet({ to: otherClient.id, from: this.client.id })
    }
  }

  createNegotiation ({ otherClientId, polite }) {
    const negotiation = new WebrtcNegotiation({
      signaller: this.signaller,
      clientId: this.client.id,
      otherClientId: otherClientId,
      polite
    })

    negotiation.peerConnection.addEventListener('track', (event) => {
      this.startStreamingFrom(otherClientId, event)
    })

    return negotiation
  }

  startStreamingTo (client) {
    if (!client.streaming) {
      this.stream.getTracks().forEach(track => {
        client.peerConnection.addTrack(track, this.stream)
      })
      client.streaming = true
    }
  }

  startStreamingFrom (id, { track, streams: [stream] }) {
    track.onunmute = () => {
      const remoteMediaElement = this.findRemoteMediaElement(id)
      if (!remoteMediaElement.srcObject) {
        remoteMediaElement.srcObject = stream
      }
    }
  }

  removeClient ({ from }) {
    if (this.clients[from]) {
      delete this.clients[from]
    }
  }

  findOrCreateClient (id) {
    return this.clients[id] || (this.clients[id] = new Client(id))
  }

  findRemoteMediaElement (clientId) {
    const target = this.remoteMediaTargets.find(
      target => target.id === `media_${clientId}`
    )
    return target ? target.querySelector('video') : null
  }

  negotiationFor (id) {
    return this.clients[id].negotiation
  }
}

RoomController.values = { id: String, clientId: String }
RoomController.targets = ['localMedia', 'remoteMedia','enter']