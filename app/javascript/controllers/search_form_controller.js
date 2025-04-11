import { Controller } from "@hotwired/stimulus"

// Enhances the search form with validation and auto-completion
export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    // Focus the input field when controller connects
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
    
    // Enhance form with validation
    this.element.addEventListener("submit", this.validateForm.bind(this))
  }
  
  // Validate the form before submission
  validateForm(event) {
    if (this.hasInputTarget && this.inputTarget.value.trim() === "") {
      event.preventDefault()
      
      // Add error styling
      this.inputTarget.classList.add("border-red-500", "ring-1", "ring-red-500")
      
      // Create error message if it doesn't exist
      if (!this.errorMessage) {
        this.errorMessage = document.createElement("p")
        this.errorMessage.classList.add("text-red-500", "text-sm", "mt-1")
        this.errorMessage.setAttribute("id", "location-error")
        this.errorMessage.textContent = "Please enter a location"
        this.inputTarget.setAttribute("aria-invalid", "true")
        this.inputTarget.setAttribute("aria-describedby", "location-error")
        this.inputTarget.after(this.errorMessage)
      }
      
      // Focus the input for accessibility
      this.inputTarget.focus()
    } else {
      // Remove error styling if input is valid
      this.removeError()
    }
  }
  
  // Handle input changes
  inputChanged() {
    if (this.hasInputTarget && this.inputTarget.value.trim() !== "") {
      this.removeError()
    }
  }
  
  // Remove error styling and message
  removeError() {
    if (this.hasInputTarget) {
      this.inputTarget.classList.remove("border-red-500", "ring-1", "ring-red-500")
      this.inputTarget.removeAttribute("aria-invalid")
      
      if (this.errorMessage) {
        this.errorMessage.remove()
        this.errorMessage = null
      }
    }
  }
}
