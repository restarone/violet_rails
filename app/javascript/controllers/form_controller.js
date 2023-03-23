import { Controller } from "@hotwired/stimulus"
import debounce from "debounce"

export default class extends Controller {
  initialize() {
    this.submit = debounce(this.submit.bind(this), 500)
  }

  submit() {
    this.element.requestSubmit();
  }
}
