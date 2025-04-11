import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  
  connect() {
    console.log("Toggle controller connected")
    // Ensure content is hidden initially using direct style
    if (this.hasContentTarget) {
      this.contentTarget.style.display = "none"
    }
  }
  
  toggle() {
    console.log("Toggle method called")
    
    if (!this.hasContentTarget) return
    
    // Get current visibility state based on display style
    const isHidden = this.contentTarget.style.display === "none"
    console.log("Current hidden state:", isHidden)
    
    // Toggle visibility using direct style manipulation
    this.contentTarget.style.display = isHidden ? "block" : "none"
    
    // Update icon rotation
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = isHidden ? "rotate(90deg)" : ""
    }
    
    console.log("New display state:", this.contentTarget.style.display)
  }
}
