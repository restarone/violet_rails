import { Controller } from '@hotwired/stimulus'
import Client from 'models/client'
import WebrtcNegotiation from 'models/webrtc_negotiation'
import RoomSubscription from 'subscriptions/room_subscription'
import Signaller from 'subscriptions/signaling_subscription'

export default class RoomController extends Controller {
  connect() {
    this.clients = {}
    this.client = new Client(this.clientIdValue)

    this.subscription = new RoomSubscription({
      delegate: this,
      id: this.idValue,
      clientId: this.client.id
    })

    this.signaller = new Signaller({
      delegate: this,
      id: this.idValue,
      clientId: this.client.id
    })

    this.client.on('iceConnection:checking', ({ detail: { otherClient } }) => {
      this.startStreamingTo(otherClient)
    })
  }

  async enter () {
    try {
      const constraints = { audio: true, video: true }
      this.client.stream = await navigator.mediaDevices.getUserMedia(constraints)
      this.localMediumTarget.srcObject = this.client.stream
      this.localMediumTarget.muted = true // Keep muted on Firefox
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

  remoteMediumTargetConnected (element) {
    const clientId = element.id.replace('medium_', '')
    this.negotiateConnection(clientId)
  }

  remoteMediumTargetDisconnected (element) {
    const clientId = element.id.replace('medium_', '')
    this.teardownClient(clientId)
  }

  negotiateConnection (clientId) {
    const otherClient = this.findOrCreateClient(clientId)

    // Be polite to newcomers!
    const polite = !!otherClient.newcomer

    otherClient.negotiation = this.createNegotiation({ otherClient, polite })

    // The polite client sets up the negotiation last, so we can start streaming
    // The impolite client signals to the other client that it's ready
    if (polite) {
      this.startStreamingTo(otherClient)
    } else {
      this.subscription.greet({ to: otherClient.id, from: this.client.id })
    }
  }

  teardownClient (clientId) {
    this.clients[clientId].stop()
    delete this.clients[clientId]
  }

  createNegotiation ({ otherClient, polite }) {
    const negotiation = new WebrtcNegotiation({
      signaller: this.signaller,
      client: this.client,
      otherClient: otherClient,
      polite
    })

    otherClient.on('track', ({ detail }) => {
      this.startStreamingFrom(otherClient.id, detail)
    })

    return negotiation
  }

  startStreamingTo (otherClient) {
    this.client.streamTo(otherClient)
  }

  startStreamingFrom (id, { track, streams: [stream] }) {
    const remoteMediaElement = this.findRemoteMediaElement(id)
    if (!remoteMediaElement.srcObject) {
      remoteMediaElement.srcObject = stream
    }
  }

  findOrCreateClient (id) {
    return this.clients[id] || (this.clients[id] = new Client(id))
  }

  findRemoteMediaElement (clientId) {
    const target = this.remoteMediumTargets.find(
      target => target.id === `medium_${clientId}`
    )
    return target ? target.querySelector('video') : null
  }

  negotiationFor (id) {
    return this.clients[id].negotiation
  }

  // RoomSubscription Delegate

  roomPinged (data) {
    this.greetNewClient(data)
  }

  // Signaler Delegate

  sdpDescriptionReceived ({ from, description }) {
    this.negotiationFor(from).setDescription(description)
  }

  iceCandidateReceived ({ from, candidate }) {
    this.negotiationFor(from).addCandidate(candidate)
  }

  negotiationRestarted ({ from }) {
    const negotiation = this.negotiationFor(from)
    negotiation.restart()
    negotiation.createOffer()
  }
}

RoomController.values = { id: String, clientId: String }
RoomController.targets = ['localMedium', 'remoteMedium', 'enter']
