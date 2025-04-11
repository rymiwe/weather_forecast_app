import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  
  initialize() {
    // Hide immediately during initialization
    if (this.hasContentTarget) {
      this.contentTarget.style.display = "none"
    }
  }
  
  connect() {
    // Double-ensure content is hidden when controller connects
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("hidden")
      this.contentTarget.style.display = "none"
    }
  }
  
  toggle() {
    if (!this.hasContentTarget) return
    
    // Check if content is currently visible
    const isHidden = this.contentTarget.style.display === "none"
    
    // Toggle visibility with style directly
    if (isHidden) {
      this.contentTarget.style.display = "block"
      this.contentTarget.classList.remove("hidden")
    } else {
      this.contentTarget.style.display = "none"
      this.contentTarget.classList.add("hidden")
    }
    
    // Update icon rotation
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = isHidden ? "rotate(90deg)" : ""
    }
  }
}
