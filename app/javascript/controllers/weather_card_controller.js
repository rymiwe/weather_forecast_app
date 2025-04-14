import { Controller } from "@hotwired/stimulus"

// Controls the weather card interactive features
export default class extends Controller {
  static targets = ["temperature", "details"]
  static classes = ["visible", "hidden", "loading"]
  
  connect() {
    // Initialize the card with proper classes for animation
    this.element.classList.add("transition-opacity")
    this.animateIn()
  }
  
  // Animate the card in using classes
  animateIn() {
    // Apply visible class after a brief delay to ensure DOM is ready
    setTimeout(() => {
      this.element.classList.add(...this.visibleClasses)
      this.element.classList.remove(...this.loadingClasses)
    }, 10)
  }
  
  // Toggle additional details visibility with accessibility support
  toggleDetails(event) {
    if (!this.hasDetailsTarget) return
    
    const isExpanded = !this.detailsTarget.classList.contains(...this.hiddenClasses)
    
    // Toggle visibility
    this.detailsTarget.classList.toggle(...this.hiddenClasses)
    
    // Update ARIA attributes for accessibility
    if (event.currentTarget.hasAttribute("aria-expanded")) {
      event.currentTarget.setAttribute("aria-expanded", !isExpanded)
    }
  }
  
  // Refresh the card data via Turbo
  refresh(event) {
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      this.element.classList.add(...this.loadingClasses)
      frame.reload()
    }
  }
}
