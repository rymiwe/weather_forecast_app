import { Controller } from "@hotwired/stimulus"

// Handles toggle functionality for expandable/collapsible sections
export default class extends Controller {
  static targets = ["trigger", "content", "icon"]
  
  connect() {
    // Set initial state from aria-expanded attribute
    const expanded = this.triggerTarget.getAttribute("aria-expanded") === "true"
    this.updateState(expanded)
  }
  
  // Toggle visibility state
  toggle(event) {
    event.preventDefault()
    
    // Get current state and toggle it
    const expanded = this.triggerTarget.getAttribute("aria-expanded") === "true"
    this.updateState(!expanded)
    
    // Manage keyboard focus for accessibility
    if (!expanded) {
      // When opening, focus the first focusable element inside
      this.focusFirstElement()
    }
  }
  
  // Update UI state based on expanded flag
  updateState(expanded) {
    // Update ARIA attributes for accessibility
    this.triggerTarget.setAttribute("aria-expanded", expanded)
    
    // Toggle content visibility
    if (expanded) {
      this.contentTarget.classList.remove("hidden")
      // Rotate icon if present
      if (this.hasIconTarget) {
        this.iconTarget.classList.add("rotate-180")
      }
    } else {
      this.contentTarget.classList.add("hidden")
      // Return icon to original position if present
      if (this.hasIconTarget) {
        this.iconTarget.classList.remove("rotate-180")
      }
    }
  }
  
  // Focus the first focusable element inside the content
  focusFirstElement() {
    // Wait for content to be visible
    setTimeout(() => {
      const focusable = this.contentTarget.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      if (focusable) {
        focusable.focus()
      }
    }, 50)
  }
}
