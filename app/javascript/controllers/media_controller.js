import { Controller } from '@hotwired/stimulus'

export default class MediaController extends Controller {
  connect () {
    this.dispatch('connect', {
      detail: { clientId: this.clientIdValue }
    })
  }



  disconnect() {
    this.dispatch('disconnect', {
      detail: { clientId: this.clientIdValue }
    })
  }

  dispatch (eventName, { target = this.element, detail = {}, bubbles = true, cancelable = true } = {}) {
    const type = `${this.identifier}:${eventName}`
    const event = new CustomEvent(type, { detail, bubbles, cancelable })
    target.dispatchEvent(event)
    return event
  }
}

MediaController.values = { clientId: String }