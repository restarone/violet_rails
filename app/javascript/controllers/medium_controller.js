import { Controller } from '@hotwired/stimulus'

export default class MediumController extends Controller {
  connect () {
    this.reRenderMediaElement()
  }

  // Fix potentially blank videos due to autoplay rules?
  reRenderMediaElement () {
    const mediaElement = this.mediaElementTarget
    const clone = mediaElement.cloneNode(true)
    mediaElement.parentNode.insertBefore(clone, mediaElement)
    mediaElement.remove()
  }
}

MediumController.targets = ['mediaElement']
