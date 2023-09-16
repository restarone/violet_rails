export default class WebrtcNegotiation {
  constructor ({ clientId, otherClientId, polite, signaller }) {
    this.clientId = clientId
    this.otherClientId = otherClientId
    this.polite = polite
    this.peerConnection = new RTCPeerConnection()
    this.signaller = signaller
    this.makingOffer = false
    this.isSettingRemoteAnswerPending = false
    this.candidates = []

    this.peerConnection.addEventListener('negotiationneeded', () => {
      this.createOffer()
    })

    this.peerConnection.addEventListener('icecandidate', ({ candidate }) => {
      this.signaller.signal({
        type: candidate ? 'candidate' : undefined,
        to: this.otherClientId,
        from: this.clientId,
        candidate
      })
    })

    this.peerConnection.addEventListener('iceconnectionstatechange', () => {
      if (this.peerConnection.iceConnectionState === 'disconnected') {
        this.signaller.signal({
          type: 'candidate:disconnected',
          from: this.otherClientId
        })
      }
    })
  }

  async createOffer () {
    try {
      this.makingOffer = true
      this.setLocalDescription(await this.peerConnection.createOffer())
    } catch (error) {
      console.error(error)
    } finally {
      this.makingOffer = false
    }
  }

  async setDescription (description) {
    try {
      if (this.ignore(description)) return

      this.setRemoteDescription(description)

      if (description.type === 'offer') {
        this.setLocalDescription(await this.peerConnection.createAnswer())
      } 
    } catch (error) {
      if (!this.ignore(description)) throw error
    }
  }

  async setLocalDescription (description) {
    await this.peerConnection.setLocalDescription(description)

    this.signaller.signal({
      type: (
        this.peerConnection.localDescription ? 'description' : undefined
      ),
      to: this.otherClientId,
      from: this.clientId,
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

  addCandidates () {
    if (this.peerConnection.remoteDescription) {
      while (this.candidates.length) {
        this.peerConnection.addIceCandidate(this.candidates.shift())
        this.addCandidates()
      }
    }
  }

  get readyForOffer() {
    return (
      !this.makingOffer &&
      (
        this.peerConnection.signalingState === 'stable' ||
        this.isSettingRemoteAnswerPending
      )
    )
  }

  collides (description) {
    return description.type === 'offer' && !this.readyForOffer
  }

  ignore (description) {
    return !this.polite && this.collides(description)
  }
}
