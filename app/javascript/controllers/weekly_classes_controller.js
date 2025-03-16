import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clubSelect", "classesContainer"]
  
  connect() {
    if (this.clubSelectTarget.value) {
      this.loadClasses()
    }
  }
  
  loadClasses() {
    const clubId = this.clubSelectTarget.value
    if (!clubId) return
    
    // Update URL to include the selected club
    const url = new URL(window.location)
    url.searchParams.set("club_id", clubId)
    history.pushState({}, "", url)
    
    // Save the last selected club
    fetch("/update_location", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({
        club_id: clubId,
        city_id: this.clubSelectTarget.selectedOptions[0].dataset.cityId
      })
    })
    
    // Load classes via Turbo
    this.classesContainerTarget.setAttribute("src", `/weekly_classes?club_id=${clubId}`)
  }
  
  bookClass(event) {
    const button = event.currentTarget
    const classId = button.dataset.classId
    const clubId = button.dataset.clubId
    const nextOccurrence = button.dataset.nextOccurrence
    const className = button.dataset.className
    const trainerName = button.dataset.trainerName
    
    if (confirm(`Book ${className} with ${trainerName}?`)) {
      button.disabled = true
      button.textContent = "Booking..."
      
      fetch("/book", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          class_id: classId,
          club_id: clubId,
          next_occurrence: nextOccurrence,
          class_name: className,
          trainer_name: trainerName
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          button.textContent = "Booked!"
          button.classList.remove("bg-indigo-600", "hover:bg-indigo-700")
          button.classList.add("bg-green-600")
        } else {
          button.textContent = "Failed"
          button.classList.remove("bg-indigo-600", "hover:bg-indigo-700")
          button.classList.add("bg-red-600")
          alert(`Booking failed: ${data.error}`)
        }
      })
      .catch(error => {
        button.textContent = "Error"
        button.disabled = false
        button.classList.remove("bg-indigo-600", "hover:bg-indigo-700")
        button.classList.add("bg-red-600")
        console.error("Error:", error)
      })
    }
  }
} 