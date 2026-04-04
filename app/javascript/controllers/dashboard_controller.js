import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cityButton", "cityMenu", "clubButton", "clubMenu", "clubsContainer", "dayTabs", "classesContainer"]

  connect() {
    this.setupDropdowns()
    this.setupSearch()
    this.currentClubId = null
    this.highlightedIndex = -1

    // Handle preselected city
    const cityValue = this.cityButtonTarget.value.trim()
    if (cityValue) {
      this.handleCitySelection(cityValue)
    }

    // Close dropdowns when clicking outside
    document.addEventListener('mousedown', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })

    // Re-setup search when turbo frames load
    document.addEventListener('turbo:frame-load', () => {
      this.setupSearch()
    })
  }

  // Stimulus action: show city dropdown on focus
  showCityDropdown() {
    this.activeInput = 'city'
    this.highlightedIndex = -1
    this.filterAndShowCityDropdown('')
  }

  // Stimulus action: filter city dropdown on input
  filterCityDropdown(event) {
    this.activeInput = 'city'
    this.highlightedIndex = -1
    this.filterAndShowCityDropdown(event.target.value.toLowerCase())
  }

  // Stimulus action: show club dropdown on focus
  showClubDropdown() {
    this.activeInput = 'club'
    this.highlightedIndex = -1
    this.filterAndShowClubDropdown('')
  }

  // Stimulus action: filter club dropdown on input
  filterClubDropdown(event) {
    this.activeInput = 'club'
    this.highlightedIndex = -1
    this.filterAndShowClubDropdown(event.target.value.toLowerCase())
  }

  // Keyboard navigation for dropdowns
  handleDropdownKeydown(event) {
    const menu = this.activeInput === 'city' ? this.cityMenuTarget : this.clubMenuTarget
    const isOpen = !menu.classList.contains('hidden')

    if (!isOpen) {
      if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault()
        if (this.activeInput === 'city') {
          this.showCityDropdown()
        } else {
          this.showClubDropdown()
        }
      }
      return
    }

    const visibleItems = Array.from(menu.querySelectorAll('.dropdown-item')).filter(
      item => item.closest('li').style.display !== 'none'
    )

    if (visibleItems.length === 0) return

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.highlightedIndex = Math.min(this.highlightedIndex + 1, visibleItems.length - 1)
        this.updateHighlight(visibleItems)
        break

      case 'ArrowUp':
        event.preventDefault()
        this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
        this.updateHighlight(visibleItems)
        break

      case 'Enter':
        event.preventDefault()
        if (this.highlightedIndex >= 0 && this.highlightedIndex < visibleItems.length) {
          visibleItems[this.highlightedIndex].click()
        } else if (visibleItems.length === 1) {
          visibleItems[0].click()
        }
        break

      case 'Tab':
        // Select the highlighted item or first visible item, then let tab proceed
        if (this.highlightedIndex >= 0 && this.highlightedIndex < visibleItems.length) {
          visibleItems[this.highlightedIndex].click()
        } else if (visibleItems.length === 1) {
          visibleItems[0].click()
        }
        // Don't prevent default — let focus move naturally
        break

      case 'Escape':
        event.preventDefault()
        this.closeAllDropdowns()
        break
    }
  }

  updateHighlight(visibleItems) {
    // Remove previous highlight
    visibleItems.forEach(item => item.classList.remove('dropdown-item-active'))

    // Add highlight to current
    if (this.highlightedIndex >= 0 && this.highlightedIndex < visibleItems.length) {
      const active = visibleItems[this.highlightedIndex]
      active.classList.add('dropdown-item-active')
      active.scrollIntoView({ block: 'nearest' })
    }
  }

  // Stimulus action: select a city from dropdown
  selectCity(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.currentTarget
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
    this.clubMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
    item.setAttribute('data-selected', 'true')

    this.clubButtonTarget.value = item.textContent.trim()
    this.closeAllDropdowns()
    this.handleClubSelection(item.dataset.value, item.dataset.city)
  }

  setupDropdowns() {
    // No-op, kept for compatibility
  }

  closeAllDropdowns() {
    this.highlightedIndex = -1
    document.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.classList.add('hidden')
      menu.style.display = ''
    })
    document.querySelectorAll('.dropdown-item-active').forEach(item => {
      item.classList.remove('dropdown-item-active')
    })
  }

  handleCitySelection(cityValue) {
    this.clubsContainerTarget.classList.toggle('hidden', !cityValue)
    this.clubButtonTarget.value = ''

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

    if (this.hasDayTabsTarget) {
      this.dayTabsTarget.querySelectorAll('button').forEach(btn => {
        if (btn.dataset.date === selectedDate) {
          btn.classList.remove('bg-surface-nested', 'text-txt-secondary', 'hover:bg-surface-hover')
          btn.classList.add('bg-accent', 'text-white', 'shadow-glow')
        } else {
          btn.classList.remove('bg-accent', 'text-white', 'shadow-glow')
          btn.classList.add('bg-surface-nested', 'text-txt-secondary', 'hover:bg-surface-hover')
        }
      })
    }

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
    const timetableId = button.dataset.timetableId

    if (bookingId) return

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
          trainer_name: trainerName,
          timetable_id: timetableId
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          button.innerHTML = `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
          </svg>`
          button.classList.remove('bg-accent-light', 'text-accent', 'hover:bg-accent', 'hover:text-white', 'hover:scale-[1.02]')
          button.classList.add('bg-success-light', 'text-success')

          const parentDiv = button.closest('.class-row')
          if (parentDiv) {
            const infoDiv = parentDiv.querySelector('.text-sm.text-txt-secondary')
            if (infoDiv && !parentDiv.querySelector('.text-success')) {
              const scheduledText = document.createElement('div')
              scheduledText.className = 'text-xs text-success mt-0.5'
              scheduledText.textContent = '✓ Rezerwacja zaplanowana'
              infoDiv.parentNode.appendChild(scheduledText)
            }
          }

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
          this.refreshOngoingBookings()
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
    if (!searchInput) return

    searchInput.removeEventListener('input', this.handleSearch)

    this.handleSearch = (e) => {
      const searchTerm = e.target.value.toLowerCase()
      document.querySelectorAll('.class-row').forEach(row => {
        const className = row.dataset.className || ''
        row.style.display = className.includes(searchTerm) ? '' : 'none'
      })
    }

    searchInput.addEventListener('input', this.handleSearch)
  }

  filterAndShowCityDropdown(searchTerm) {
    const cityMenu = this.cityMenuTarget
    const items = cityMenu.querySelectorAll('.dropdown-item')
    let hasVisibleItems = false

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

    if (hasVisibleItems) {
      cityMenu.classList.remove('hidden')
      cityMenu.style.display = 'block'
    } else {
      cityMenu.classList.add('hidden')
      cityMenu.style.display = ''
    }
  }

  filterAndShowClubDropdown(searchTerm) {
    const clubMenu = this.clubMenuTarget
    let hasVisibleItems = false

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
      clubMenu.style.display = 'block'
    } else {
      clubMenu.classList.add('hidden')
      clubMenu.style.display = ''
    }
  }
}
