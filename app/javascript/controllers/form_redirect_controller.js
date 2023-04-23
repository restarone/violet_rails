import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  next(event) {
    event.preventDefault();
    if (event.detail.success) {
      const fetchResponse = event.detail.fetchResponse

      history.pushState(
        { turbo_frame_history: true },
        "",
        fetchResponse.response.url
      )

      Turbo.visit(fetchResponse.response.url)
    }
  }
}
