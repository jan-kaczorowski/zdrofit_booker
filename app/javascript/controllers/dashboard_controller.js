import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cityButton", "cityMenu", "clubButton", "clubMenu", "clubsContainer", "dayTabs", "classesContainer"]

  connect() {
    console.log("Dashboard controller connected")
    this.setupDropdowns()
    this.setupSearch()
    this.currentClubId = null

    // Handle preselected city
    const cityValue = this.cityButtonTarget.value.trim()
    if (cityValue) {
      this.handleCitySelection(cityValue)
    }

    // Close dropdowns when clicking outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })

    // Re-setup search when turbo frames load
    document.addEventListener('turbo:frame-load', (e) => {
      this.setupSearch()
    })
  }

  setupDropdowns() {
    // Set up city typeahead
    this.cityButtonTarget.addEventListener('input', (e) => {
      const searchTerm = e.target.value.toLowerCase()
      const cityMenu = this.cityMenuTarget
      let hasVisibleItems = false

      cityMenu.querySelectorAll('.dropdown-item').forEach(item => {
        const cityName = item.textContent.toLowerCase()
        if (cityName.includes(searchTerm)) {
          item.closest('li').style.display = ''
          hasVisibleItems = true
        } else {
          item.closest('li').style.display = 'none'
        }
      })

      if (searchTerm.length > 0 && hasVisibleItems) {
        cityMenu.classList.remove('hidden')
      } else {
        cityMenu.classList.add('hidden')
      }
    })

    // Set up club typeahead
    this.clubButtonTarget.addEventListener('input', (e) => {
      const searchTerm = e.target.value.toLowerCase()
      const clubMenu = this.clubMenuTarget
      let hasVisibleItems = false

      clubMenu.querySelectorAll('.dropdown-item').forEach(item => {
        const clubName = item.textContent.toLowerCase()
        if (clubName.includes(searchTerm)) {
          item.closest('li').style.display = ''
          hasVisibleItems = true
        } else {
          item.closest('li').style.display = 'none'
        }
      })

      if (searchTerm.length > 0 && hasVisibleItems) {
        clubMenu.classList.remove('hidden')
      } else {
        clubMenu.classList.add('hidden')
      }
    })

    // Set up city dropdown items
    this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()

        this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        item.setAttribute('data-selected', 'true')

        this.cityButtonTarget.value = item.textContent
        this.closeAllDropdowns()
        this.handleCitySelection(item.dataset.value)
      })
    })

    // Set up club dropdown items
    this.clubMenuTarget.parentElement.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()

        this.clubMenuTarget.parentElement.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        item.setAttribute('data-selected', 'true')

        this.clubButtonTarget.value = item.textContent
        this.closeAllDropdowns()
        this.handleClubSelection(item.dataset.value, item.dataset.city)
      })
    })
  }

  closeAllDropdowns() {
    document.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.classList.add('hidden')
    })
  }

  handleCitySelection(cityValue) {
    this.clubsContainerTarget.classList.toggle('hidden', !cityValue)
    this.clubButtonTarget.value = ''

    // Filter club dropdown items
    const clubItems = this.clubMenuTarget.parentElement.querySelectorAll('.dropdown-item')
    clubItems.forEach(item => {
      const showOption = !cityValue || item.dataset.city === cityValue
      item.closest('li').style.display = showOption ? '' : 'none'
    })
  }

  handleClubSelection(clubId, cityName) {
    this.currentClubId = clubId
    this.loadClasses(clubId)
  }

  loadClasses(clubId, selectedDate = null) {
    const weeklyClassesFrame = document.getElementById('weekly-classes-container')

    if (weeklyClassesFrame) {
      let url = `/weekly_classes?club_id=${clubId}`
      if (selectedDate) {
        url += `&date=${selectedDate}`
      }
      weeklyClassesFrame.setAttribute('src', url)
      weeklyClassesFrame.classList.remove('hidden')
    }
  }

  selectDay(event) {
    const selectedDate = event.currentTarget.dataset.date

    // Update tab styles
    if (this.hasDayTabsTarget) {
      this.dayTabsTarget.querySelectorAll('button').forEach(btn => {
        if (btn.dataset.date === selectedDate) {
          btn.classList.remove('bg-gray-100', 'text-gray-700', 'hover:bg-gray-200')
          btn.classList.add('bg-indigo-600', 'text-white')
        } else {
          btn.classList.remove('bg-indigo-600', 'text-white')
          btn.classList.add('bg-gray-100', 'text-gray-700', 'hover:bg-gray-200')
        }
      })
    }

    // Reload classes for the selected date
    if (this.currentClubId) {
      this.loadClasses(this.currentClubId, selectedDate)
    }
  }

  bookClass(event) {
    const button = event.currentTarget
    const bookingId = button.dataset.bookingId
    const classId = button.dataset.classId
    const clubId = button.dataset.clubId
    const nextOccurrence = button.dataset.nextOccurrence
    const className = button.dataset.className
    const trainerName = button.dataset.trainerName

    // If already booked, do nothing
    if (bookingId) {
      return
    }

    if (confirm(`Schedule auto-booking for ${className}?`)) {
      button.disabled = true

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
          // Update button to show booked state
          button.innerHTML = `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
          </svg>`
          button.classList.remove('bg-indigo-100', 'text-indigo-600', 'hover:bg-indigo-200')
          button.classList.add('bg-green-100', 'text-green-600')

          // Add "Auto-booking scheduled" text
          const parentDiv = button.closest('.class-row')
          if (parentDiv) {
            const infoDiv = parentDiv.querySelector('.text-sm.text-gray-500')
            if (infoDiv && !parentDiv.querySelector('.text-green-600')) {
              const scheduledText = document.createElement('div')
              scheduledText.className = 'text-xs text-green-600 mt-0.5'
              scheduledText.textContent = '✓ Auto-booking scheduled'
              infoDiv.parentNode.appendChild(scheduledText)
            }
          }

          // Refresh the ongoing bookings frame
          this.refreshOngoingBookings()
        } else {
          alert(`Booking failed: ${data.error}`)
          button.disabled = false
        }
      })
      .catch(error => {
        console.error("Error:", error)
        button.disabled = false
        alert("An error occurred while booking the class.")
      })
    }
  }

  cancelBooking(event) {
    const button = event.currentTarget
    const bookingId = button.dataset.bookingId
    const className = button.dataset.className

    if (confirm(`Cancel auto-booking for ${className}?`)) {
      button.disabled = true
      button.textContent = "Canceling..."

      fetch(`/bookings/${bookingId}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Refresh the ongoing bookings frame
          this.refreshOngoingBookings()

          // Refresh the weekly classes if a club is selected
          if (this.currentClubId) {
            this.loadClasses(this.currentClubId)
          }
        } else {
          alert(`Failed to cancel: ${data.error}`)
          button.disabled = false
          button.textContent = "Cancel"
        }
      })
      .catch(error => {
        console.error("Error:", error)
        button.disabled = false
        button.textContent = "Cancel"
        alert("An error occurred while canceling the booking.")
      })
    }
  }

  refreshOngoingBookings() {
    const ongoingBookingsFrame = document.getElementById('ongoing-bookings-container')
    if (ongoingBookingsFrame) {
      ongoingBookingsFrame.setAttribute('src', '/ongoing_bookings')
    }
  }

  setupSearch() {
    const searchInput = document.getElementById('class-search')

    if (!searchInput) {
      return
    }

    // Remove existing listener to avoid duplicates
    searchInput.removeEventListener('input', this.handleSearch)

    // Create bound handler
    this.handleSearch = (e) => {
      const searchTerm = e.target.value.toLowerCase()
      const classRows = document.querySelectorAll('.class-row')

      classRows.forEach(row => {
        const className = row.dataset.className || ''
        if (className.includes(searchTerm)) {
          row.style.display = ''
        } else {
          row.style.display = 'none'
        }
      })
    }

    searchInput.addEventListener('input', this.handleSearch)
  }

  showDebugInfo(e) {
    const btn = e.target.closest('button.debug-button')
    if (btn) {
      const object = JSON.parse(btn.dataset.object)
      console.table(object)
    }
  }
}
