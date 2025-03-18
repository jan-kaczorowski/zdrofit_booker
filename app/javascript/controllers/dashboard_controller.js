import { Controller } from "@hotwired/stimulus"

// Version: 2023-06-14-001
export default class extends Controller {
  static targets = ["cityButton", "cityMenu", "clubButton", "clubMenu", "clubsContainer"]
  
  connect() {
    console.log("Dashboard controller connected - v2")
    this.setupDropdowns()
    this.setupSearch()

    // Ensure the city selection is handled correctly
    const cityValue = this.cityButtonTarget.value.trim()
    if (cityValue) {
      console.log('chrum', cityValue)
      this.handleCitySelection(cityValue)
    }

    // Close dropdowns when clicking outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })

    document.addEventListener('turbo:frame-load', (e) => {
      console.log('turbo:frame-load event triggered', e)
      this.setupSearch()
    })

    document.addEventListener('turbo:after-stream-render', (e) => {
      console.log('turbo:after-stream-render event triggered', e)
      this.setupSearch()
    })
  }
  
  setupDropdowns() {
    console.log("Setting up dropdowns")
    
    // Set up city typeahead
    this.cityButtonTarget.addEventListener('input', (e) => {
      const searchTerm = e.target.value.toLowerCase();
      const cityMenu = this.cityMenuTarget;
      let hasVisibleItems = false;

      cityMenu.querySelectorAll('.dropdown-item').forEach(item => {
        const cityName = item.textContent.toLowerCase();
        if (cityName.includes(searchTerm)) {
          item.closest('li').style.display = '';
          hasVisibleItems = true;
        } else {
          item.closest('li').style.display = 'none';
        }
      });

      // Toggle dropdown visibility
      if (searchTerm.length > 0 && hasVisibleItems) {
        cityMenu.classList.remove('hidden');
        cityMenu.classList.add('show');
      } else {
        cityMenu.classList.add('hidden');
        cityMenu.classList.remove('show');
      }
    });

    // Set up club typeahead
    this.clubButtonTarget.addEventListener('input', (e) => {
      const searchTerm = e.target.value.toLowerCase();
      const clubMenu = this.clubMenuTarget;
      let hasVisibleItems = false;

      clubMenu.querySelectorAll('.dropdown-item').forEach(item => {
        const clubName = item.textContent.toLowerCase();
        if (clubName.includes(searchTerm)) {
          item.closest('li').style.display = '';
          hasVisibleItems = true;
        } else {
          item.closest('li').style.display = 'none';
        }
      });

      // Toggle dropdown visibility
      if (searchTerm.length > 0 && hasVisibleItems) {
        clubMenu.classList.remove('hidden');
        clubMenu.classList.add('show');
      } else {
        clubMenu.classList.add('hidden');
        clubMenu.classList.remove('show');
      }
    });

    // Set up city dropdown items
    this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()
        
        // Remove data-selected from all items
        this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        // Set data-selected on clicked item
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
        
        // Remove data-selected from all items
        this.clubMenuTarget.parentElement.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        // Set data-selected on clicked item
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
      menu.classList.remove('show')
      const btn = menu.previousElementSibling
      if (btn) {
        btn.setAttribute('aria-expanded', 'false')
        const arrow = btn.querySelector('svg')
        if (arrow) arrow.style.transform = ''
      }
    })
  }
  
  handleCitySelection(cityValue) {
    // Show clubs container
    this.clubsContainerTarget.classList.toggle('hidden', !cityValue)
    
    // Reset club dropdown text
    this.clubButtonTarget.querySelector('span').textContent = 'Select a club...'
    
    // Filter club dropdown items
    const clubItems = this.clubMenuTarget.parentElement.querySelectorAll('.dropdown-item')
    clubItems.forEach(item => {
      const showOption = !cityValue || item.dataset.city === cityValue
      item.closest('li').style.display = showOption ? '' : 'none'
    })
    this.setupSearch();
  }
  
  handleClubSelection(clubId, cityName) {
    // Load classes for this club
    this.loadClasses(clubId, cityName)
  }
  
  loadClasses(clubId, cityName) {
    console.log(`Loading classes for club ${clubId} in ${cityName}`)
    
    // Get the Turbo Frame element
    const weeklyClassesFrame = document.getElementById('weekly-classes-container')
    
    // Set the src attribute to load classes for the selected club
    if (weeklyClassesFrame) {
      weeklyClassesFrame.setAttribute('src', `/weekly_classes?club_id=${clubId}`)
      
      // Make the frame visible if it was hidden
      weeklyClassesFrame.classList.remove('hidden')
    } else {
      console.error('Could not find weekly-classes-container element')
    }
  }
  
  sayHello() {
    alert("Hello from Stimulus! Updated version")
    console.log("sayHello method called")
  }

  showDebugInfo(e) {
    
    const btn = e.target.closest('button.debug-button')
    console.log("showDebugInfo method called",btn)
    const object = JSON.parse(btn.dataset.object)
    console.table(object)
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

  setupSearch() {
    const searchInput = document.getElementById('class-search')
    console.log('setupSearch method called', searchInput)
    
    // Check if the search input exists
    if (!searchInput) {
      console.warn("Search input not found")
      return
    }

    const tableRows = document.querySelectorAll('#weekly-classes-container tbody tr')

    searchInput.addEventListener('input', function() {
      console.log('searchInput.addEventListener input method called', searchInput.value)
      const searchTerm = searchInput.value.toLowerCase()

      tableRows.forEach(row => {
        const className = row.querySelector('td:nth-child(2)').textContent.toLowerCase()
        if (className.includes(searchTerm)) {
          row.style.display = ''
        } else {
          row.style.display = 'none'
        }
      })
    })
  }
} 