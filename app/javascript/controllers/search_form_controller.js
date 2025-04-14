import { Controller } from "@hotwired/stimulus"

// Enhances the search form with validation and auto-completion
export default class extends Controller {
  static targets = ["input", "error"]
  static classes = ["invalid", "errorVisible"]
  
  connect() {
    // Focus the input field when controller connects if not on mobile
    if (this.hasInputTarget && window.innerWidth > 768) {
      this.inputTarget.focus()
    }
    
    // Enhance form with validation
    this.element.addEventListener("submit", this.validate.bind(this))
  }
  
  // Validate the form before submission
  validate(event) {
    if (!this.hasInputTarget) return
    
    const inputValue = this.inputTarget.value.trim()
    
    if (inputValue === "") {
      event.preventDefault()
      this.showError("Please enter a location")
    } else {
      this.hideError()
    }
  }
  
  // Clear error when user starts typing
  inputChanged() {
    if (this.inputTarget.value.trim() !== "") {
      this.hideError()
    }
  }
  
  showError(message) {
    // Add invalid classes to input
    this.inputTarget.classList.add(...this.invalidClasses)
    this.inputTarget.setAttribute("aria-invalid", "true")
    
    // Show error message
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.add(...this.errorVisibleClasses)
      this.errorTarget.removeAttribute("hidden")
      
      // Announce error to screen readers
      this.errorTarget.setAttribute("role", "alert")
    }
  }
  
  hideError() {
    // Remove invalid classes from input
    if (this.hasInputTarget) {
      this.inputTarget.classList.remove(...this.invalidClasses)
      this.inputTarget.setAttribute("aria-invalid", "false")
    }
    
    // Hide error message
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove(...this.errorVisibleClasses)
      this.errorTarget.setAttribute("hidden", "")
      this.errorTarget.removeAttribute("role")
    }
  }
}
