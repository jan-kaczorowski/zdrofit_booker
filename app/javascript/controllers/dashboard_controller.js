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

    // Close dropdowns when clicking outside (with delay to allow click events to process)
    document.addEventListener('mousedown', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })

    // Re-setup search when turbo frames load
    document.addEventListener('turbo:frame-load', (e) => {
      this.setupSearch()
    })
  }

  // Stimulus action: show city dropdown on focus
  showCityDropdown() {
    console.log("[Dashboard] showCityDropdown action triggered")
    this.filterAndShowCityDropdown('')
  }

  // Stimulus action: filter city dropdown on input
  filterCityDropdown(event) {
    console.log("[Dashboard] filterCityDropdown action triggered:", event.target.value)
    this.filterAndShowCityDropdown(event.target.value.toLowerCase())
  }

  // Stimulus action: show club dropdown on focus
  showClubDropdown() {
    console.log("[Dashboard] showClubDropdown action triggered")
    this.filterAndShowClubDropdown('')
  }

  // Stimulus action: filter club dropdown on input
  filterClubDropdown(event) {
    console.log("[Dashboard] filterClubDropdown action triggered:", event.target.value)
    this.filterAndShowClubDropdown(event.target.value.toLowerCase())
  }

  // Stimulus action: select a city from dropdown
  selectCity(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.currentTarget
    console.log("[Dashboard] selectCity action triggered:", item.dataset.value)

    this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
    item.setAttribute('data-selected', 'true')

    this.cityButtonTarget.value = item.textContent.trim()
    this.closeAllDropdowns()
    this.handleCitySelection(item.dataset.value)
  }

  // Stimulus action: select a club from dropdown
  selectClub(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.currentTarget
    console.log("[Dashboard] selectClub action triggered:", item.dataset.value)

    this.clubMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
    item.setAttribute('data-selected', 'true')

    this.clubButtonTarget.value = item.textContent.trim()
    this.closeAllDropdowns()
    this.handleClubSelection(item.dataset.value, item.dataset.city)
  }

  setupDropdowns() {
    console.log("[Dashboard] Setting up dropdowns")
    console.log("[Dashboard] City menu has", this.cityMenuTarget.querySelectorAll('.dropdown-item').length, "items")
    console.log("[Dashboard] Club menu has", this.clubMenuTarget.querySelectorAll('.dropdown-item').length, "items")
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

    if (confirm(`Zaplanować automatyczną rezerwację na ${className}?`)) {
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
              scheduledText.textContent = '✓ Rezerwacja zaplanowana'
              infoDiv.parentNode.appendChild(scheduledText)
            }
          }

          // Refresh the ongoing bookings frame
          this.refreshOngoingBookings()
        } else {
          alert(`Rezerwacja nie powiodła się: ${data.error}`)
          button.disabled = false
        }
      })
      .catch(error => {
        console.error("Error:", error)
        button.disabled = false
        alert("Wystąpił błąd podczas rezerwacji zajęć.")
      })
    }
  }

  cancelBooking(event) {
    const button = event.currentTarget
    const bookingId = button.dataset.bookingId
    const className = button.dataset.className

    if (confirm(`Anulować rezerwację na ${className}?`)) {
      button.disabled = true
      button.textContent = "Anulowanie..."

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
          alert(`Nie udało się anulować: ${data.error}`)
          button.disabled = false
          button.textContent = "Anuluj"
        }
      })
      .catch(error => {
        console.error("Error:", error)
        button.disabled = false
        button.textContent = "Anuluj"
        alert("Wystąpił błąd podczas anulowania rezerwacji.")
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

  filterAndShowCityDropdown(searchTerm) {
    const cityMenu = this.cityMenuTarget
    const items = cityMenu.querySelectorAll('.dropdown-item')
    let hasVisibleItems = false

    console.log(`[City Dropdown] Filtering for: "${searchTerm}", found ${items.length} items`)

    items.forEach(item => {
      const cityName = item.textContent.toLowerCase().trim()
      const matches = searchTerm === '' || cityName.includes(searchTerm)

      if (matches) {
        item.closest('li').style.display = ''
        hasVisibleItems = true
      } else {
        item.closest('li').style.display = 'none'
      }
    })

    console.log(`[City Dropdown] Has visible items: ${hasVisibleItems}`)

    if (hasVisibleItems) {
      cityMenu.classList.remove('hidden')
    } else {
      cityMenu.classList.add('hidden')
    }
  }

  filterAndShowClubDropdown(searchTerm) {
    const clubMenu = this.clubMenuTarget
    let hasVisibleItems = false

    // Get currently selected city to filter clubs
    const selectedCityItem = this.cityMenuTarget.querySelector('.dropdown-item[data-selected="true"]')
    const selectedCity = selectedCityItem?.dataset.value

    clubMenu.querySelectorAll('.dropdown-item').forEach(item => {
      const clubName = item.textContent.toLowerCase()
      const clubCity = item.dataset.city
      const matchesSearch = searchTerm === '' || clubName.includes(searchTerm)
      const matchesCity = !selectedCity || clubCity === selectedCity

      if (matchesSearch && matchesCity) {
        item.closest('li').style.display = ''
        hasVisibleItems = true
      } else {
        item.closest('li').style.display = 'none'
      }
    })

    if (hasVisibleItems) {
      clubMenu.classList.remove('hidden')
    } else {
      clubMenu.classList.add('hidden')
    }
  }
}
