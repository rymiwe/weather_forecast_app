import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static classes = ["hidden", "visible", "expanded"]
  static values = {
    label: { type: String, default: "" }
  }
  
  connect() {
    // Set initial ARIA attributes for accessibility
    if (this.element.hasAttribute("aria-controls")) {
      // If aria-controls is already set, use that
      const contentId = this.element.getAttribute("aria-controls")
      if (this.hasContentTarget && !this.contentTarget.id) {
        this.contentTarget.id = contentId
      }
    } else if (this.hasContentTarget) {
      // Otherwise, create an ID for the content
      const contentId = `toggle-content-${Date.now()}`
      this.contentTarget.id = contentId
      this.element.setAttribute("aria-controls", contentId)
    }
    
    // Set initial expanded state
    const isExpanded = this.hasContentTarget && !this.contentTarget.classList.contains(...this.hiddenClasses)
    this.element.setAttribute("aria-expanded", isExpanded)
    
    // Set aria-label if provided
    if (this.labelValue && this.element.tagName !== "BUTTON") {
      this.element.setAttribute("aria-label", this.labelValue)
    }
    
    // Make sure the element is keyboard navigable
    if (!this.element.hasAttribute("tabindex")) {
      this.element.setAttribute("tabindex", "0")
    }
    
    // Add keyboard event listener
    this.element.addEventListener("keydown", this.handleKeyDown.bind(this))
  }
  
  disconnect() {
    // Remove keyboard event listener
    this.element.removeEventListener("keydown", this.handleKeyDown.bind(this))
  }
  
  toggle(event) {
    if (!this.hasContentTarget) return
    
    // Toggle visibility using CSS classes
    this.contentTarget.classList.toggle(...this.hiddenClasses)
    
    // Determine if content is now visible
    const isExpanded = !this.contentTarget.classList.contains(...this.hiddenClasses)
    
    // Update ARIA attributes
    this.element.setAttribute("aria-expanded", isExpanded)
    
    // Update icon with CSS classes instead of inline styles
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle(...this.expandedClasses, isExpanded)
    }
    
    // Announce change to screen readers if not using a native button
    if (this.element.tagName !== "BUTTON" && isExpanded) {
      this.announceExpandCollapse(isExpanded)
    }
  }
  
  handleKeyDown(event) {
    // Handle keyboard interaction
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.toggle(event)
    }
  }
  
  announceExpandCollapse(isExpanded) {
    // Create a live region for screen reader announcements
    const announcement = document.createElement("div")
    announcement.setAttribute("aria-live", "polite")
    announcement.classList.add("sr-only") // Screen reader only
    announcement.textContent = isExpanded ? "Details expanded" : "Details collapsed"
    
    document.body.appendChild(announcement)
    
    // Remove after announcement is made
    setTimeout(() => {
      document.body.removeChild(announcement)
    }, 1000)
  }
}
