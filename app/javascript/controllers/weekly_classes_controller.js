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
  
  sayHello() {
    alert("Hello from Stimulus! Updated version")
    console.log("sayHello method called")
  }


} 