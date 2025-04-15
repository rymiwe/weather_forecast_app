import { Controller } from "@hotwired/stimulus"

// Tooltip controller for developer debugging tooltips
export default class extends Controller {
  static targets = ["tooltip"]

  show() {
    this.tooltipTarget.classList.add("show")
    this.tooltipTarget.classList.remove("hidden")
  }

  hide() {
    this.tooltipTarget.classList.remove("show")
    this.tooltipTarget.classList.add("hidden")
  }
}
