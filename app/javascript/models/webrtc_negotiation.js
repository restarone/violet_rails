const RETRY_LIMIT = 10
const peerConnectionConfig = {
  iceServers: [
    {
      urls: [
        'stun:stun.l.google.com:19302',
        'stun:global.stun.twilio.com:3478'
      ]
    }
  ],
  sdpSemantics: 'unified-plan'
}

export default class WebrtcNegotiation {
  constructor ({ client, otherClient, polite, signaller }) {
    this.client = client
    this.otherClient = otherClient
    this.polite = polite
    this.signaller = signaller
    this.makingOffer = false
    this.isSettingRemoteAnswerPending = false
    this.candidates = []
    this.retryCount = 0

    this.start()
  }

  async createOffer () {
    if (!this.readyToMakeOffer) return

    try {
      this.makingOffer = true
      await this.setLocalDescription(await this.peerConnection.createOffer())
    } catch (error) {
      console.error(error)
    } finally {
      this.makingOffer = false
    }
  }

  async setDescription (description) {
    try {
      if (this.ignore(description)) return

      await this.setRemoteDescription(description)

      if (description.type === 'offer') {
        await this.setLocalDescription(await this.peerConnection.createAnswer())
      }
    } catch (error) {
      if (this.retryCount < RETRY_LIMIT) {
        this.initiateManualRollback()
        this.retryCount++
      } else {
        this.stop()
        console.error(`Negotiation failed after ${this.retryCount} retries`)
      }
    }
  }

  async setLocalDescription (description) {
    await this.peerConnection.setLocalDescription(description)

    this.signaller.signal({
      type: this.peerConnection.localDescription ? 'description' : undefined,
      to: this.otherClient.id,
      from: this.client.id,
      description: this.peerConnection.localDescription
    })
  }

  async setRemoteDescription (description) {
    this.isSettingRemoteAnswerPending = description.type === 'answer'
    await this.peerConnection.setRemoteDescription(description) // SRD rolls back as needed
    this.addCandidates()
    this.isSettingRemoteAnswerPending = false
  }

  addCandidate (candidate) {
    this.candidates.push(candidate)
    this.addCandidates()
  }

  // TODO try/catch and ignore failures if necessary?
  addCandidates () {
    if (this.peerConnection.remoteDescription) {
      while (this.candidates.length) {
        this.peerConnection.addIceCandidate(this.candidates.shift())
      }
    }
  }

  get readyToMakeOffer () {
    return !this.makingOffer && this.peerConnection.signalingState === 'stable'
  }

  get readyToReceiveOffer () {
    return !this.makingOffer && (
      this.peerConnection.signalingState === 'stable' ||
      this.isSettingRemoteAnswerPending
    )
  }

  collides (description) {
    return description.type === 'offer' && !this.readyToReceiveOffer
  }

  ignore (description) {
    return !this.polite && this.collides(description)
  }

  initiateManualRollback() {
    this.restart()
    this.signaller.signal({
      type: 'restart',
      to: this.otherClient.id,
      from: this.client.id
    })
  }

  restart() {
    this.stop()
    this.start()
  }

  start () {
    this.setupPeerConnection()
  }

  stop () {
    this.makingOffer = false
    this.isSettingRemoteAnswerPending = false
    this.candidates = []
    this.teardownPeerConnection()
    this.otherClient.streaming = false
  }

  setupPeerConnection () {
    this.peerConnection = new RTCPeerConnection(peerConnectionConfig)

    this._onnegotiationneeded = () => this.createOffer()

    this._onicecandidate = ({ candidate }) => {
      this.signaller.signal({
        type: candidate ? 'candidate' : undefined,
        to: this.otherClient.id,
        from: this.client.id,
        candidate
      })
    }

    this._oniceconnectionstatechange = (event) => {
      this.client.broadcast(`iceConnection:${this.peerConnection.iceConnectionState}`, { otherClient: this.otherClient })

      switch (this.peerConnection.iceConnectionState) {
      case 'completed':
        this.retryCount = 0
        break;
      case 'failed':
        if ('restartIce' in this.peerConnection) this.peerConnection.restartIce()
        break;
      default:
        return
      }
    }

    this._ontrack = (event) => this.otherClient.broadcast('track', event)

    this.peerConnection.addEventListener('negotiationneeded', this._onnegotiationneeded)
    this.peerConnection.addEventListener('icecandidate', this._onicecandidate)
    this.peerConnection.addEventListener('iceconnectionstatechange', this._oniceconnectionstatechange)
    this.peerConnection.addEventListener('track', this._ontrack)
  }

  teardownPeerConnection () {
    this.peerConnection.close()
    this.peerConnection.removeEventListener('negotiationneeded', this._onnegotiationneeded)
    this.peerConnection.removeEventListener('icecandidate', this._onicecandidate)
    this.peerConnection.removeEventListener('iceconnectionstatechange', this._oniceconnectionstatechange)
    this.peerConnection.removeEventListener('track', this._ontrack)
    this.peerConnection = null
  }
}
