import { Controller } from "@hotwired/stimulus"

// Controls the weather card interactive features
export default class extends Controller {
  static targets = ["temperature", "details"]
  
  connect() {
    // Log connection for debugging
    console.log("Weather card controller connected")
    
    // Apply any animations or initial state
    this.initializeCard()
  }
  
  // Initialize the card with animations
  initializeCard() {
    // Add fade-in animation
    this.element.classList.add("transition-opacity")
    this.element.style.opacity = "0"
    
    // Delay slightly to ensure DOM is ready
    setTimeout(() => {
      this.element.style.opacity = "1"
    }, 10)
  }
  
  // Toggle additional details visibility
  toggleDetails(event) {
    if (this.hasDetailsTarget) {
      this.detailsTarget.classList.toggle("hidden")
    }
  }
  
  // Method to handle unit conversion requests
  // Called via data-action from the view
  updateUnits(event) {
    // This would be triggered when the user requests a unit change
    const unitSelector = event.currentTarget
    const newUnit = unitSelector.value
    
    // Dispatch a custom event that parent controllers can listen for
    const changeEvent = new CustomEvent("units-changed", { 
      detail: { unit: newUnit },
      bubbles: true
    })
    
    this.element.dispatchEvent(changeEvent)
  }
}
